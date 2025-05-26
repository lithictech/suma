# frozen_string_literal: true

RSpec.describe "Suma::Marketing::List", :db do
  let(:described_class) { Suma::Marketing::List }

  describe "list specification" do
    it "includes only transport-enabled, undeleted members" do
      m = Suma::Fixtures.member.with_preferences.create
      disabled = Suma::Fixtures.member.with_preferences(sms_enabled: false).create
      deleted = Suma::Fixtures.member.with_preferences.create
      deleted.soft_delete
      es = Suma::Fixtures.member.with_preferences(preferred_language: "es").create

      spec = described_class::Specification.new(
        label: "mylist", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )
      expect(spec.members_dataset.all).to have_same_ids_as(m)
    end

    it "includes opted-in marketing lists" do
      en_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: en_member, preferred_language: "en")

      es_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: es_member, preferred_language: "es")

      unsubscribed = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: unsubscribed, preferred_language: "en", marketing_sms_optout: true)

      specs = described_class::Specification.gather_all
      en = specs.find { |s| s.full_label == "Marketing - SMS - English" }
      es = specs.find { |s| s.full_label == "Marketing - SMS - Spanish" }
      expect(en.members_dataset.all).to have_same_ids_as(en_member)
      expect(es.members_dataset.all).to have_same_ids_as(es_member)
    end

    it "includes recently unverified members" do
      en_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: en_member, preferred_language: "en")

      es_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: es_member, preferred_language: "es")

      verified = Suma::Fixtures.member.onboarding_verified.create
      Suma::Message::Preferences.create(member: verified)

      old = Suma::Fixtures.member.create(created_at: 2.months.ago)
      Suma::Message::Preferences.create(member: old)

      specs = described_class::Specification.gather_all
      en = specs.find { |s| s.full_label == "Unverified, last 30 days - SMS - English" }
      es = specs.find { |s| s.full_label == "Unverified, last 30 days - SMS - Spanish" }
      expect(en.members_dataset.all).to have_same_ids_as(en_member)
      expect(es.members_dataset.all).to have_same_ids_as(es_member)
    end

    it "includes per-organization list" do
      en_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: en_member, preferred_language: "en")

      es_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: es_member, preferred_language: "es")

      o1 = Suma::Fixtures.organization.create(name: "Org 1")
      o2 = Suma::Fixtures.organization.create(name: "Org 2")
      Suma::Fixtures.organization_membership.verified(o1).create(member: en_member)
      Suma::Fixtures.organization_membership.verified(o2).create(member: en_member)
      Suma::Fixtures.organization_membership.verified(o1).create(member: es_member)

      specs = described_class::Specification.gather_all
      o1_en_spec = specs.find { |s| s.full_label == "Org 1 - SMS - English" }
      o1_es_spec = specs.find { |s| s.full_label == "Org 1 - SMS - Spanish" }
      o2_en_spec = specs.find { |s| s.full_label == "Org 2 - SMS - English" }
      o2_es_spec = specs.find { |s| s.full_label == "Org 2 - SMS - Spanish" }
      expect(o1_en_spec.members_dataset.all).to have_same_ids_as(en_member)
      expect(o1_es_spec.members_dataset.all).to have_same_ids_as(es_member)
      expect(o2_en_spec.members_dataset.all).to have_same_ids_as(en_member)
      expect(o2_es_spec.members_dataset.all).to be_empty
    end
  end

  describe "list generation" do
    it "creates and adds members to the managed list" do
      member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member:, preferred_language: "en")

      spec = described_class::Specification.new(
        label: "mylist", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )
      list = described_class.rebuild(spec)
      expect(list).to have_attributes(
        label: "mylist - SMS - English",
        managed: true,
      )
      expect(list.members).to contain_exactly(be === member)
    end

    it "deletes managed lists no longer in the specification" do
      spec1 = described_class::Specification.new(
        label: "mylist1", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )
      spec2 = described_class::Specification.new(
        label: "mylist2", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )
      spec3 = described_class::Specification.new(
        label: "mylist3", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )
      explicit_list = Suma::Fixtures.marketing_list.create(label: "customlist")
      lists = described_class.rebuild_all(spec1, spec2)
      expect(lists).to contain_exactly(
        have_attributes(label: "mylist1 - SMS - English"),
        have_attributes(label: "mylist2 - SMS - English"),
      )
      expect(described_class.all).to contain_exactly(
        have_attributes(label: "mylist1 - SMS - English"),
        have_attributes(label: "mylist2 - SMS - English"),
        have_attributes(label: "customlist"),
      )

      lists = described_class.rebuild_all(spec3, spec2)
      expect(lists).to contain_exactly(
        have_attributes(label: "mylist3 - SMS - English"),
        have_attributes(label: "mylist2 - SMS - English"),
      )
      expect(described_class.all).to contain_exactly(
        have_attributes(label: "mylist3 - SMS - English"),
        have_attributes(label: "mylist2 - SMS - English"),
        have_attributes(label: "customlist"),
      )
    end

    it "replaces list members on update" do
      spec = described_class::Specification.new(
        label: "mylist", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )

      member1 = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: member1, preferred_language: "en")
      member2 = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: member2, preferred_language: "en")

      list = described_class.rebuild(spec)
      expect(list.members).to contain_exactly(be === member1, be === member2)

      member3 = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: member3, preferred_language: "en")
      member2.soft_delete

      list = described_class.rebuild(spec)
      expect(list.members).to contain_exactly(be === member1, be === member3)
    end
  end
end
