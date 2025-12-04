# frozen_string_literal: true

require "suma/admin_api/members"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Members, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/members" do
    it "returns all members" do
      u = Array.new(2) { Suma::Fixtures.member.create }

      get "/v1/members"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(admin, *u))
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      get "/v1/members"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/members" }
      let(:search_term) { "ZZZ" }

      def make_matching_items
        return [
          Suma::Fixtures.member(email: "zzz@example.org").create,
          Suma::Fixtures.member(name: "Zzz Zam").create,
        ]
      end

      def make_non_matching_items
        return [
          admin,
          Suma::Fixtures.member(name: "wibble wobble").create,
        ]
      end
    end

    it "will search a US phone number as an E164 form in search", :hybrid_search do
      nomatch = Suma::Fixtures.member(phone: "19998887777").create
      match = Suma::Fixtures.member(phone: "13334445555").create

      Suma::Member.hybrid_search_reindex_all

      get "/v1/members", search: "x (333) 444-5555 y"

      expect(last_response).to have_status(200)
      expect(last_response_json_body[:items]).to have_same_ids_as(match).ordered
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/members" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return admin.update(created_at: created) if i.zero?
        return Suma::Fixtures.member.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/members" }
      let(:order_by_field) { "opaque_id" }
      def make_item(i)
        return admin.update(opaque_id: i.to_s) if i.zero?
        return Suma::Fixtures.member.create(created_at: Time.now + rand(1..100).days, opaque_id: i.to_s)
      end
    end
  end

  describe "GET /v1/members/:id" do
    it "returns the member" do
      get "/v1/members/#{admin.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(:roles, id: admin.id)
    end

    it "403s if the member does not exist" do
      get "/v1/members/0"

      expect(last_response).to have_status(403)
    end

    it "represents detailed info" do
      cash_ledger = Suma::Fixtures.ledger.member(admin).category(:cash).create
      Suma::Fixtures.charge(member: admin).create
      Suma::Fixtures.book_transaction.from(cash_ledger).create
      Suma::Fixtures.card.member(admin).create
      Suma::Fixtures.bank_account.member(admin).create
      admin.preferences!.update(preferred_language: "es")

      get "/v1/members/#{admin.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        sessions: contain_exactly(include(:ip_lookup_link)),
        preferences: include(preferred_language_name: "Spanish"),
      )
    end

    describe "reset codes" do
      it "includes tokens if the admin has access" do
        admin.remove_all_roles
        admin.add_role(Suma::Role.cache.onboarding_manager)
        admin.add_role(Suma::Role.cache.sensitive_messages)

        rc = Suma::Fixtures.reset_code.create

        get "/v1/members/#{rc.member.id}"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(
          reset_codes: contain_exactly(
            include(token: rc.token),
          ),
        )
      end

      it "hides tokens if the admin does not have access" do
        admin.remove_all_roles
        admin.add_role(Suma::Role.cache.onboarding_manager)

        rc = Suma::Fixtures.reset_code.create

        get "/v1/members/#{rc.member.id}"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(
          reset_codes: contain_exactly(
            include(token: "******"),
          ),
        )
      end
    end
  end

  describe "POST /v1/members/:id" do
    it "updates the member" do
      member = Suma::Fixtures.member.create

      post "/v1/members/#{member.id}", name: "b 2", email: "b@gmail.com", phone: "12223334444"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: member.id, name: "b 2", email: "b@gmail.com", phone: "12223334444")
    end

    it "400s if a phone number is taken, with instructions message for admins" do
      member = Suma::Fixtures.member.create
      member_taken = Suma::Fixtures.member.create(phone: "15553335555")

      post "/v1/members/#{member.id}", phone: member_taken.phone

      expect(last_response).to have_status(400)
      message = /duplicate a member, make sure that you soft-delete their account first/
      expect(last_response).to have_json_body.that_includes(error: include(message:))
    end

    it "replaces roles if given" do
      existing = Suma::Role.create(name: "existing")
      to_remove = Suma::Role.create(name: "to_remove")
      to_add = Suma::Role.create(name: "to_add")
      member = Suma::Fixtures.member.with_role(existing).with_role(to_remove).create

      post "/v1/members/#{member.id}", roles: [{id: existing.id}, {id: to_add.id}]

      expect(last_response).to have_status(200)
      expect(member.refresh.roles.map(&:name)).to contain_exactly("existing", "to_add")
      expect(member.refresh.audit_activities).to contain_exactly(have_attributes(message_name: "rolechange"))
    end

    describe "with an admin who cannot modify roles" do
      let(:to_add) { Suma::Role.create(name: "to_add") }
      let(:member) { Suma::Fixtures.member.create }
      before(:each) do
        admin.remove_all_roles
        admin.add_role(Suma::Role.cache.onboarding_manager)
      end

      it "errors if updating roles" do
        post "/v1/members/#{member.id}", roles: [{id: to_add.id}]

        expect(last_response).to have_status(403)
        expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
      end

      it "succeeds if not updating roles" do
        post "/v1/members/#{member.id}", name: "hello"

        expect(last_response).to have_status(200)
        expect(member.refresh).to have_attributes(name: "hello")
      end
    end

    it "updates legal entity if given" do
      legal_entity = Suma::Fixtures.legal_entity.create
      member = Suma::Fixtures.member.with_legal_entity(legal_entity).create

      post "/v1/members/#{member.id}", legal_entity: {
        id: legal_entity.id,
        name: "hello",
        address: {
          address1: "main st",
          address2: "apt 1",
          city: "Portland",
          state_or_province: "OR",
          postal_code: "97214",
          country: "US",
        },
      }

      expect(last_response).to have_status(200)
      expect(member.refresh.legal_entity).to have_attributes(
        id: legal_entity.id, address: have_attributes(address1: "main st"),
      )
    end

    it "updates preferences given" do
      member = Suma::Fixtures.member.create
      member.preferences!

      post "/v1/members/#{member.id}", preferences: {sms_undeliverable: true}

      expect(last_response).to have_status(200)
      expect(member.refresh.preferences).to have_attributes(sms_undeliverable_at: match_time(:now))
    end

    it "removes/updates/creates memberships for the member if given" do
      member = Suma::Fixtures.member.create
      fac = Suma::Fixtures.organization_membership(member:)
      membership_to_delete = fac.verified.create
      membership_to_update = fac.verified.create
      unverified_membership_to_verify = fac.unverified.create
      unverified_membership_no_update = fac.unverified.create
      new_org = Suma::Fixtures.organization.create(name: "Affordable Housing Program")
      org_update1 = Suma::Fixtures.organization.create
      org_update2 = Suma::Fixtures.organization.create
      org_for_new_membership = Suma::Fixtures.organization.create

      post "/v1/members/#{member.id}",
           organization_memberships: [
             {
               id: membership_to_update.id,
               verified_organization: {id: org_update1.id},
             },
             {
               id: unverified_membership_to_verify.id,
               verified_organization: {id: org_update2.id},
             },
             {
               id: unverified_membership_no_update.id,
               verified_organization: nil,
             },
             {
               verified_organization: {id: org_for_new_membership.id},
             },
           ]

      expect(last_response).to have_status(200)
      expect(membership_to_delete).to be_destroyed
      expect(member.refresh.organization_memberships).to contain_exactly(
        have_attributes(id: membership_to_update.id, verified_organization: be === org_update1),
        have_attributes(id: unverified_membership_to_verify.id, verified_organization: be === org_update2),
        have_attributes(id: unverified_membership_no_update.id, verified_organization: nil),
        have_attributes(verified_organization: be === org_for_new_membership),
      )
    end

    it "reassigns legal entity if just an ID is given" do
      legal_entity1 = Suma::Fixtures.legal_entity.create
      legal_entity2 = Suma::Fixtures.legal_entity.create
      member = Suma::Fixtures.member.with_legal_entity(legal_entity1).create

      post "/v1/members/#{member.id}", legal_entity: {id: legal_entity2.id}

      expect(last_response).to have_status(200)
      expect(member.refresh.legal_entity).to have_attributes(id: legal_entity2.id)
    end
  end

  describe "POST /v1/members/:id/close" do
    it "soft deletes the member" do
      member = Suma::Fixtures.member.create
      post "/v1/members/#{member.id}/close"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: member.id, soft_deleted_at: be_present)
      expect(member.refresh).to be_soft_deleted
    end

    it "does not re-delete" do
      orig_at = 2.hours.ago
      member = Suma::Fixtures.member.create(soft_deleted_at: orig_at)

      post "/v1/members/#{member.id}/close"

      expect(last_response).to have_status(200)
      expect(member.refresh.soft_deleted_at).to be_within(1).of(orig_at)
    end

    it "adds an activity" do
      member = Suma::Fixtures.member.create
      post "/v1/members/#{member.id}/close"

      expect(last_response).to have_status(200)
      expect(Suma::Member.last.audit_activities).to contain_exactly(have_attributes(message_name: "accountclosed"))
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.readonly_admin)

      post "/v1/members/1/close"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "POST /v1/members/:id/notes/create" do
    let(:member) { Suma::Fixtures.member.create }

    it "creates a note" do
      post "/v1/members/#{member.id}/notes/create", content: "hello"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(notes: contain_exactly(include(content: "hello", author: include(id: admin.id))))
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.readonly_admin)

      post "/v1/members/#{member.id}/notes/create", content: "hello"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "POST /v1/members/:id/notes/:id/update" do
    let(:member) { Suma::Fixtures.member.create }

    it "updates a note" do
      note = Suma::Fixtures.support_note.annotate(member).create

      post "/v1/members/#{member.id}/notes/#{note.id}", content: "hello"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(notes: contain_exactly(include(content: "hello", author: include(id: admin.id))))
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.readonly_admin)

      note = Suma::Fixtures.support_note.annotate(member).create

      post "/v1/members/#{member.id}/notes/#{note.id}", content: "hello"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

    it "errors if the note is not associated" do
      note = Suma::Fixtures.support_note.create

      post "/v1/members/#{member.id}/notes/#{note.id}", content: "hello"

      expect(last_response).to have_status(403)
    end
  end
end
