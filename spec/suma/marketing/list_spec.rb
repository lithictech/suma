# frozen_string_literal: true

RSpec.describe "Suma::Marketing::List", :db do
  let(:described_class) { Suma::Marketing::List }

  it "cascades deletes" do
    list = Suma::Fixtures.marketing_list.create
    list.add_member(Suma::Fixtures.member.create)
    broadcast = Suma::Fixtures.marketing_sms_broadcast.create
    broadcast.add_list(list)
    expect { list.destroy }.to_not raise_error
  end

  it "has members and broadcasts associations" do
    li = Suma::Fixtures.marketing_list.create
    m = Suma::Fixtures.member.create
    li.add_member(m)
    expect(li.members).to contain_exactly(be === m)
    expect(m.marketing_lists).to contain_exactly(be === li)
    c = Suma::Fixtures.marketing_sms_broadcast.create
    li.add_sms_broadcast(c)
    expect(li.sms_broadcasts).to contain_exactly(be === c)
    expect(c.lists).to contain_exactly(be === li)
  end

  describe "list specification" do
    it "includes only transport-enabled, undeleted members" do
      m = Suma::Fixtures.member.with_preferences.create
      disabled = Suma::Fixtures.member.with_preferences(sms_enabled: false).create
      deleted = Suma::Fixtures.member.with_preferences.create
      deleted.soft_delete

      spec = described_class::Specification.new(
        label: "mylist", transport: :sms, members_dataset: Suma::Member.dataset,
      )
      expect(spec.members_dataset.all).to have_same_ids_as(m)
    end

    it "includes opted-in marketing lists" do
      member = Suma::Fixtures.member.with_preferences.create
      unsubscribed = Suma::Fixtures.member.with_preferences(marketing_sms_optout: true).create
      noprefs = Suma::Fixtures.member.create

      specs = described_class::Specification.gather_all
      list = specs.find { |s| s.full_label == "Marketing - SMS" }
      expect(list.members_dataset.all).to have_same_ids_as(member)
    end

    it "includes recently unverified members" do
      member = Suma::Fixtures.member.with_preferences.create
      verified = Suma::Fixtures.member.onboarding_verified.with_preferences.create
      old = Suma::Fixtures.member.with_preferences.create(created_at: 2.months.ago)

      specs = described_class::Specification.gather_all
      list = specs.find { |s| s.full_label == "Unverified, last 30 days - SMS" }
      expect(list.members_dataset.all).to have_same_ids_as(member)
    end

    it "includes per-organization list" do
      member = Suma::Fixtures.member.with_preferences.create

      o1 = Suma::Fixtures.organization.create(name: "Org 1")
      o2 = Suma::Fixtures.organization.create(name: "Org 2")
      o3 = Suma::Fixtures.organization.create(name: "Org 3")
      Suma::Fixtures.organization_membership.verified(o1).create(member:)
      Suma::Fixtures.organization_membership.verified(o2).create(member:)

      specs = described_class::Specification.gather_all
      o1_spec = specs.find { |s| s.full_label == "Org 1 - SMS" }
      o2_spec = specs.find { |s| s.full_label == "Org 2 - SMS" }
      o3_spec = specs.find { |s| s.full_label == "Org 3 - SMS" }
      expect(o1_spec.members_dataset.all).to have_same_ids_as(member)
      expect(o2_spec.members_dataset.all).to have_same_ids_as(member)
      expect(o3_spec.members_dataset.all).to be_empty
    end
  end

  describe "list generation" do
    it "creates and adds members to the managed list" do
      member = Suma::Fixtures.member.with_preferences.create
      spec = described_class::Specification.new(
        label: "mylist", transport: :sms, members_dataset: Suma::Member.dataset,
      )
      list = described_class.rebuild(spec)
      expect(list).to have_attributes(
        label: "mylist - SMS",
        managed: true,
      )
      expect(list.members).to contain_exactly(be === member)
    end

    it "deletes managed lists no longer in the specification" do
      spec1 = described_class::Specification.new(
        label: "mylist1", transport: :sms, members_dataset: Suma::Member.dataset,
      )
      spec2 = described_class::Specification.new(
        label: "mylist2", transport: :sms, members_dataset: Suma::Member.dataset,
      )
      spec3 = described_class::Specification.new(
        label: "mylist3", transport: :sms, members_dataset: Suma::Member.dataset,
      )
      explicit_list = Suma::Fixtures.marketing_list.create(label: "customlist")
      lists = described_class.rebuild_all(spec1, spec2)
      expect(lists).to contain_exactly(
        have_attributes(label: "mylist1 - SMS"),
        have_attributes(label: "mylist2 - SMS"),
      )
      expect(described_class.all).to contain_exactly(
        have_attributes(label: "mylist1 - SMS"),
        have_attributes(label: "mylist2 - SMS"),
        have_attributes(label: "customlist"),
      )

      lists = described_class.rebuild_all(spec3, spec2)
      expect(lists).to contain_exactly(
        have_attributes(label: "mylist3 - SMS"),
        have_attributes(label: "mylist2 - SMS"),
      )
      expect(described_class.all).to contain_exactly(
        have_attributes(label: "mylist3 - SMS"),
        have_attributes(label: "mylist2 - SMS"),
        have_attributes(label: "customlist"),
      )
    end

    it "replaces list members on update" do
      spec = described_class::Specification.new(
        label: "mylist", transport: :sms, members_dataset: Suma::Member.dataset,
      )

      member1 = Suma::Fixtures.member.with_preferences.create
      member2 = Suma::Fixtures.member.with_preferences.create

      list = described_class.rebuild(spec)
      expect(list.members).to contain_exactly(be === member1, be === member2)

      member3 = Suma::Fixtures.member.with_preferences.create
      member2.soft_delete

      list = described_class.rebuild(spec)
      expect(list.members).to contain_exactly(be === member1, be === member3)
    end
  end
end
