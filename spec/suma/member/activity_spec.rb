# frozen_string_literal: true

# rubocop:disable Layout/LineLength
RSpec.describe "Suma::Member::Activity", :db do
  let(:described_class) { Suma::Member::Activity }

  it "can fixture" do
    o = Suma::Fixtures.organization.create
    a = Suma::Fixtures.member_activity.subject(o).create
    expect(o.audit_activities).to have_same_ids_as(a)
  end
  it "can use an integer or text subject id" do
    expect { Suma::Fixtures.member_activity.create(subject_id: "1") }.to_not raise_error
    expect { Suma::Fixtures.member_activity.create(subject_id: "abc") }.to_not raise_error
  end

  describe "HasActivityAudit" do
    let(:auditable) { Suma::Fixtures.organization.create(name: "MyOrg") }
    let(:member) { Suma::Fixtures.member.create(email: "x@y.z") }

    it "adds an activity to the member, and the subject dataset" do
      a = auditable.audit_activity(
        "testactivity",
        member:,
        summary: "hi",
      )
      expect(a.values).to include(
        message_name: "testactivity",
        subject_id: auditable.id.to_s,
        subject_type: "Suma::Organization",
        summary: "hi",
      )
      expect(member.activities).to have_same_ids_as(a)
      expect(auditable.audit_activities).to have_same_ids_as(a)
    end

    it "calculates summary with a prefix and action" do
      a = auditable.audit_activity(
        "testactivity",
        member:,
        prefix: "hello",
        action: "world",
      )
      expect(a).to have_attributes(summary: "helloworld")
    end

    it "calculates summary with a prefix" do
      a = auditable.audit_activity(
        "testactivity",
        member:,
        prefix: "hello",
      )
      expect(a).to have_attributes(summary: "hello")
    end

    it "calculates summary with an action" do
      a = auditable.audit_activity(
        "testactivity",
        member:,
        action: "world",
      )
      expect(a).to have_attributes(
        summary: "x@y.z performed testactivity on Suma::Organization[#{auditable.id}] 'MyOrg': world",
      )
    end

    it "calculates summary without any hint arguments" do
      a = auditable.audit_activity(
        "testactivity",
        member:,
      )
      expect(a).to have_attributes(
        summary: "x@y.z performed testactivity on Suma::Organization[#{auditable.id}] 'MyOrg'",
      )
    end

    it "calculates summary on receivers without a name" do
      auditable.instance_eval do
        undef :name
      end
      a = auditable.audit_activity(
        "testactivity",
        member:,
      )
      expect(a).to have_attributes(
        summary: "x@y.z performed testactivity on Suma::Organization[#{auditable.id}]",
      )
    end

    it "can use an object as an action (has name method)" do
      o = Suma::Fixtures.organization.create(name: "OtherOrg")
      a = auditable.audit_activity(
        "testactivity",
        member:,
        action: o,
      )
      expect(a).to have_attributes(
        summary: "x@y.z performed testactivity on Suma::Organization[#{auditable.id}] 'MyOrg': Suma::Organization[#{o.id}] 'OtherOrg'",
      )
    end

    it "can use an object as an action (no name method)" do
      o = Suma::Fixtures.organization.create
      o.instance_eval do
        undef :name
      end
      a = auditable.audit_activity(
        "testactivity",
        member:,
        action: o,
      )
      expect(a).to have_attributes(
        summary: "x@y.z performed testactivity on Suma::Organization[#{auditable.id}] 'MyOrg': Suma::Organization[#{o.id}]",
      )
    end
  end
end
# rubocop:enable Layout/LineLength
