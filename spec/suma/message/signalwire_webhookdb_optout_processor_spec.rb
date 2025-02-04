# frozen_string_literal: true

require "suma/message/signalwire_webhookdb_optout_processor"

RSpec.describe Suma::Message::SignalwireWebhookdbOptoutProcessor, :db, reset_configuration: Suma::Signalwire do
  before(:each) do
    Suma::Signalwire.marketing_number = "+12225550000"
  end

  let(:member_phone) { "14445556666" }

  def messagerow(swid, body: "STOP", **kw)
    r = {
      signalwire_id: swid,
      date_created: 4.days.ago,
      direction: "inbound",
      from: "+12225551234",
      to: Suma::Signalwire.marketing_number,
      data: {body:}.to_json,
    }
    r.merge!(**kw)
    return r
  end

  it "finds potential unsubscribe rows from the last week" do
    old = messagerow("msg2", date_created: 8.days.ago)
    wrong_to = messagerow("msg3", to: "+13334445555")
    wrong_message = messagerow("msg4", body: "Hello")

    stop = messagerow("msg10")
    spaces_and_casing = messagerow("msg11", body: " stop ")
    start = messagerow("msg12", body: "Start ")
    help = messagerow("msg13", body: " HELP")

    Suma::Webhookdb.signalwire_messages_dataset.multi_insert(
      [old, wrong_to, wrong_message, stop, spaces_and_casing, start, help],
    )
    result = described_class.new(now: Time.now).fetch_rows
    expect(result).to contain_exactly(
      include(signalwire_id: "msg10"),
      include(signalwire_id: "msg11"),
      include(signalwire_id: "msg12"),
      include(signalwire_id: "msg13"),
    )
  end

  it "updates preferences of members matching the phone number of unsubscribe rows" do
    member = Suma::Fixtures.member.create(phone: member_phone)
    Suma::Webhookdb.signalwire_messages_dataset.insert(messagerow("msg1", from: "+" + member_phone))
    described_class.new(now: Time.now).run
    expect(member.refresh.preferences!).to have_attributes(marketing_sms_optout: true)
  end

  it "skips messages from unknown members" do
    Suma::Webhookdb.signalwire_messages_dataset.insert(messagerow("msg1"))
    expect { described_class.new(now: Time.now).run }.to_not raise_error
  end

  it "is idempotent" do
    member = Suma::Fixtures.member.create(phone: member_phone)
    Suma::Webhookdb.signalwire_messages_dataset.insert(messagerow("msg1", from: "+" + member_phone))
    described_class.new(now: Time.now).run
    expect(member.refresh.preferences!).to have_attributes(marketing_sms_optout: true)

    member.refresh.preferences!.update(marketing_sms_optout: false)

    described_class.new(now: Time.now).run
    expect(member.refresh.preferences!).to have_attributes(marketing_sms_optout: false)
  end

  it "processes texts in order, to handle multiple actions from the same number" do
    member = Suma::Fixtures.member.create(phone: member_phone)

    Suma::Webhookdb.signalwire_messages_dataset.insert(messagerow("msg1", from: "+" + member_phone, body: "STOP"))
    Suma::Webhookdb.signalwire_messages_dataset.insert(messagerow("msg2", from: "+" + member_phone, body: "START"))
    described_class.new(now: Time.now).run
    expect(member.refresh.preferences!).to have_attributes(marketing_sms_optout: false)
  end

  it "texts the user about subscription changes" do
    member = Suma::Fixtures.member.create(phone: member_phone)
    Suma::Webhookdb.signalwire_messages_dataset.multi_insert(
      [
        messagerow("msg1", from: "+" + member_phone),
        messagerow("msg2", from: "+" + member_phone, body: "START"),
        messagerow("msg3", from: "+" + member_phone, body: "help"),
      ],
    )
    described_class.new(now: Time.now).run
    expect(Suma::Message::Delivery.all).to contain_exactly(
      have_attributes(recipient: be === member, template: "sms_compliance/optout"),
      have_attributes(recipient: be === member, template: "sms_compliance/optin"),
      have_attributes(recipient: be === member, template: "sms_compliance/help"),
    )
  end

  describe "msgtype" do
    it "errors for a row that matches no keywords" do
      expect { described_class.new(now: Time.now).msgtype("foo") }.to raise_error(Suma::InvariantViolation)
    end
  end

  describe "run" do
    it "errors for a malformed signalwire 'from' number" do
      Suma::Webhookdb.signalwire_messages_dataset.insert(messagerow("msg", from: "12223334444"))
      expect { described_class.new(now: Time.now).run }.to raise_error(Suma::InvariantViolation)
    end
  end
end
