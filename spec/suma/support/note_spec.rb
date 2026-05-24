# frozen_string_literal: true

RSpec.describe "Suma::Support::Note", :db do
  let(:described_class) { Suma::Support::Note }

  it "is associated annotated resources" do
    member = Suma::Fixtures.member.create
    ver = Suma::Fixtures.organization_membership_verification.create

    note = Suma::Support::Note.create(content: "hi")
    note.add_member(member)
    ver.add_note(note)

    expect(note.members).to have_same_ids_as(member)
    expect(member.notes).to have_same_ids_as(note)

    expect(note.organization_membership_verifications).to have_same_ids_as(ver)
    expect(ver.notes).to have_same_ids_as(note)
  end

  describe "combined_notes association" do
    it "combines and sorts verification and member notes" do
      content = "hi"
      v = Suma::Fixtures.organization_membership_verification.create
      m = v.membership.member
      vn1 = v.add_note(content:, edited_at: 4.hours.ago)
      vn2 = v.add_note(content:, created_at: 2.hours.ago)
      vn3 = v.add_note(content:, created_at: 3.hours.ago)
      mn1 = m.add_note(content:, created_at: 5.hours.ago)
      mn2 = m.add_note(content:, edited_at: 1.hours.ago)

      other_vn = Suma::Fixtures.organization_membership_verification.create.add_note(content:)

      expect(v.combined_notes).to have_same_ids_as(mn2, vn2, vn3, vn1, mn1).ordered
      eagered_v = refetch_for_eager(v)
      expect(eagered_v.combined_notes).to have_same_ids_as(mn2, vn2, vn3, vn1, mn1).ordered

      expect(m.combined_notes).to have_same_ids_as(mn2, vn2, vn3, vn1, mn1).ordered
      eagered_m = refetch_for_eager(m)
      expect(eagered_m.combined_notes).to have_same_ids_as(mn2, vn2, vn3, vn1, mn1).ordered
    end

    it "handles notes on members shared between eager loaded instances" do
      m1 = Suma::Fixtures.member.create
      m2 = Suma::Fixtures.member.create
      m1v1 = Suma::Fixtures.organization_membership_verification.member(m1).create
      m1v2 = Suma::Fixtures.organization_membership_verification.member(m1).create
      m2v1 = Suma::Fixtures.organization_membership_verification.member(m2).create
      m1note = m1.add_note(content: "m1note")
      m2note = m2.add_note(content: "m2note")
      m1v1note = m1v1.add_note(content: "m1v1note")
      m1v2note = m1v2.add_note(content: "m1v2note")
      m2v1note = m2v1.add_note(content: "m2v1note")

      expect(m1v1.combined_notes).to have_same_ids_as(m1note, m1v1note)
      expect(m1v2.combined_notes).to have_same_ids_as(m1note, m1v2note)
      expect(m1.combined_notes).to have_same_ids_as(m1note, m1v1note, m1v2note)
      expect(m2v1.combined_notes).to have_same_ids_as(m2note, m2v1note)
      expect(m2.combined_notes).to have_same_ids_as(m2note, m2v1note)

      eagered_verifications = Suma::Organization::Membership::Verification.dataset.all
      m1v1 = eagered_verifications.find { |v| v === m1v1 }
      m1v2 = eagered_verifications.find { |v| v === m1v2 }
      m2v1 = eagered_verifications.find { |v| v === m2v1 }

      eagered_members = Suma::Member.all
      m1 = eagered_members.find { |m| m === m1 }
      m2 = eagered_members.find { |m| m === m2 }

      expect(m1v1.combined_notes).to have_same_ids_as(m1note, m1v1note)
      expect(m1v2.combined_notes).to have_same_ids_as(m1note, m1v2note)
      expect(m1.combined_notes).to have_same_ids_as(m1note, m1v1note, m1v2note)
      expect(m2v1.combined_notes).to have_same_ids_as(m2note, m2v1note)
      expect(m2.combined_notes).to have_same_ids_as(m2note, m2v1note)
    end
  end

  describe "rendering" do
    it "renders markdown to html" do
      m = Suma::Fixtures.member.create
      note = m.add_note(content: "hello **there**")
      expect(note.content_html).to eq("hello <strong>there</strong>")
    end

    it "automatically converts non-markdown hyperlinks" do
      # rubocop:disable Layout/LineLength
      m = Suma::Fixtures.member.create
      note = m.add_note(content: "https://h1.org https://h2.org [https://h3.com](https://h3.com) https://h4.com")
      expect(note.content_md).to eq("[https://h1.org](https://h1.org) [https://h2.org](https://h2.org) [https://h3.com](https://h3.com) [https://h4.com](https://h4.com)")
      # rubocop:enable Layout/LineLength
    end
  end

  describe "creator/editor fields" do
    let(:admin) { Suma::Fixtures.member.create }
    let(:member) { Suma::Fixtures.member.create }

    it "sets the creator to the request admin on create" do
      note = Suma.set_request_user_and_admin(member, admin) do
        Suma::Fixtures.support_note.create
      end
      expect(note).to have_attributes(
        creator: be === admin,
        created_at: match_time(:now),
        editor: nil,
        edited_at: nil,
      )
    end

    it "sets the editor to the request editor on update" do
      t1 = 10.hours.ago
      t2 = 9.hours.ago
      t3 = 8.hours.ago
      t4 = 7.hours.ago

      note = Suma.set_request_user_and_admin(member, admin) do
        Suma::Fixtures.support_note.create(created_at: t1, content: "1")
      end

      admin2 = Suma::Fixtures.member.admin.create
      note = Suma.set_request_user_and_admin(member, admin2) do
        Timecop.freeze(t2) { note.update(content: "2") }
      end
      expect(note).to have_attributes(
        creator: be === admin,
        created_at: match_time(t1),
        editor: be === admin2,
        edited_at: match_time(t2),
      )

      admin3 = Suma::Fixtures.member.admin.create
      note = Suma.set_request_user_and_admin(member, admin3) do
        Timecop.freeze(t3) { note.update(content: "3") }
      end
      expect(note).to have_attributes(
        editor: be === admin3,
        edited_at: match_time(t3),
      )

      Timecop.freeze(t4) { note.update(content: "4") }
      expect(note).to have_attributes(
        editor: be_nil,
        edited_at: match_time(t4),
      )
    end

    it "does not modify edit fields if content has not changed" do
      note = Suma::Fixtures.support_note.create
      expect(note).to have_attributes(edited_at: nil)
      note.update(created_at: 1.hour.ago)
      expect(note).to have_attributes(edited_at: nil)
      note.update(content: "")
      expect(note).to have_attributes(edited_at: match_time(:now))
    end
  end
end
