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

  describe "summary_md" do
    it "parses and renders the summary" do
      a = described_class.new(message_name: "removeexclusion")
      a.summary = "a@lithic.tech performed removeexclusion on Suma::Program[39] 'A Market 2025': Suma::Organization[7](enrollee: Suma::Member[439] 'Person x' Suma::Payment::FakeStrategy[1])"
      expect(a.summary_md).to eq("<span class=\"email\">a@lithic.tech</span> performed <span class=\"action\">removeexclusion</span> on [<code class=\"code\">Program[39]</code>](/program/39) <span class=\"quote\">'A Market 2025'</span>: [<code class=\"code\">Organization[7]</code>](/organization/7)(enrollee: [<code class=\"code\">Member[439]</code>](/member/439) <span class=\"quote\">'Person x'</span> <code class=\"code\">Suma::Payment::FakeStrategy[1]</code>)")
    end
  end

  describe "HasActivityAudit" do
    let(:auditable) { Suma::Fixtures.organization.create(name: "MyOrg") }
    let(:actor) { Suma::Fixtures.member.create(email: "x@y.z") }

    it "adds an activity to the member, and the subject dataset" do
      a = auditable.audit_activity(
        "testactivity",
        actor:,
        summary: "hi",
      )
      expect(a.values).to include(
        message_name: "testactivity",
        subject_id: auditable.id.to_s,
        subject_type: "Suma::Organization",
        summary: "hi",
      )
      expect(actor.activities).to have_same_ids_as(a)
      expect(auditable.audit_activities).to have_same_ids_as(a)
    end

    describe "the actor" do
      it "has an email templated into the default action, if present" do
        a = auditable.audit_activity("test", actor:)
        expect(a.values).to include(
          summary: /x@y\.z performed test/,
        )
      end

      it "uses the actor name if email is not present" do
        actor.update(email: nil, name: "Jim")
        a = auditable.audit_activity("test", actor:)
        expect(a.values).to include(
          summary: /Jim performed test/,
        )
      end

      it "defaults to the request admin" do
        a = Suma.set_request_user_and_admin(Suma::Fixtures.member.create, actor) do
          auditable.audit_activity("test")
        end
        expect(a.values).to include(
          summary: /x@y\.z performed test/,
        )
      end

      it "falls back to the request user" do
        a = Suma.set_request_user_and_admin(actor, nil) do
          auditable.audit_activity("test")
        end
        expect(a.values).to include(
          summary: /x@y\.z performed test/,
        )
      end

      it "errors if no actor is given and there is no request info or user" do
        expect { auditable.audit_activity("test") }.to raise_error(ArgumentError, /actor must be provided/)
      end
    end

    it "calculates summary with a prefix and action" do
      a = auditable.audit_activity(
        "testactivity",
        actor:,
        prefix: "hello",
        action: "world",
      )
      expect(a).to have_attributes(summary: "helloworld")
    end

    it "calculates summary with a prefix" do
      a = auditable.audit_activity(
        "testactivity",
        actor:,
        prefix: "hello",
      )
      expect(a).to have_attributes(summary: "hello")
    end

    it "calculates summary with an action" do
      a = auditable.audit_activity(
        "testactivity",
        actor:,
        action: "world",
      )
      expect(a).to have_attributes(
        summary: "x@y.z performed testactivity on Suma::Organization[#{auditable.id}] 'MyOrg': world",
      )
    end

    it "calculates summary without any hint arguments" do
      a = auditable.audit_activity(
        "testactivity",
        actor:,
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
        actor:,
      )
      expect(a).to have_attributes(
        summary: "x@y.z performed testactivity on Suma::Organization[#{auditable.id}]",
      )
    end

    it "can use an object as an action (has name method)" do
      o = Suma::Fixtures.organization.create(name: "OtherOrg")
      a = auditable.audit_activity(
        "testactivity",
        actor:,
        action: o,
      )
      expect(a).to have_attributes(
        summary: "x@y.z performed testactivity on Suma::Organization[#{auditable.id}] 'MyOrg': Suma::Organization[#{o.id}] 'OtherOrg'",
      )
    end

    it "can use an object as an action (has name object method)" do
      o = Suma::Fixtures.organization.create
      o.instance_eval do
        def name = Suma::TranslatedText.new(en: "blah")
      end
      a = auditable.audit_activity(
        "testactivity",
        actor:,
        action: o,
      )
      expect(a).to have_attributes(
        summary: "x@y.z performed testactivity on Suma::Organization[#{auditable.id}] 'MyOrg': Suma::Organization[#{o.id}] 'blah'",
      )
    end

    it "can use an object as an action (no name method)" do
      o = Suma::Fixtures.organization.create
      o.instance_eval do
        undef :name
      end
      a = auditable.audit_activity(
        "testactivity",
        actor:,
        action: o,
      )
      expect(a).to have_attributes(
        summary: "x@y.z performed testactivity on Suma::Organization[#{auditable.id}] 'MyOrg': Suma::Organization[#{o.id}]",
      )
    end
  end
end
# rubocop:enable Layout/LineLength
