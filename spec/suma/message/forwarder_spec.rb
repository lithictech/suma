# frozen_string_literal: true

require "suma/message/forwarder"

RSpec.describe Suma::Message::Forwarder, :db, :no_transaction_check, reset_configuration: Suma::Message::Forwarder do
  before(:each) do
    Suma::Message::Forwarder.phone_numbers = ["15552223333", "+12224445555"]
    Suma::Message::Forwarder.front_inbox_id = "1234"
  end

  def messagerow(swid, data={})
    r = {
      signalwire_id: swid,
      date_created: data[:date_created] || Time.now,
      direction: "inbound",
      from: data[:from] || "+14445551234",
      to: data[:to] || Suma::PhoneNumber.format_e164(Suma::Message::Forwarder.phone_numbers.sample),
      data: data.to_json,
    }
    return r
  end

  def insert_message(swid, data={}) = Suma::Webhookdb.signalwire_messages_dataset.insert(messagerow(swid, data))

  it "syncs recent messages sent to the configured numbers into the configured Front inbox" do
    old = insert_message("msg2", date_created: Time.at(1_749_920_264) - 8.days)
    wrong_to = insert_message("msg3", to: "+13334445555")
    msg1 = insert_message("msg1", body: "hello", date_created: Time.at(1_749_921_156))

    req = stub_request(:post, "https://api2.frontapp.com/inboxes/inb_ya/imported_messages").
      with(body: {
        sender: {handle: "alt:phone:+14445551234"},
        to: ["alt:phone:+14445551234"],
        body: "hello",
        external_id: "msg1",
        created_at: 1_749_921_156,
        type: "sms",
        metadata: {is_inbound: true, is_archived: false},
      }.to_json).to_return(json_response({}))

    described_class.new(now: Time.now).run
    expect(req).to have_been_made
  end

  it "is idempotent" do
    insert_message("msg1", body: "hello", date_created: Time.at(1_749_921_156))
    req = stub_request(:post, "https://api2.frontapp.com/inboxes/inb_ya/imported_messages").
      to_return(json_response({}))

    described_class.new(now: Time.now).run
    described_class.new(now: Time.now).run
    expect(req).to have_been_made.once
  end

  it "errors if the Front inbox is not set" do
    described_class.front_inbox_id = ""
    expect do
      described_class.new(now: Time.now).run
    end.to raise_error(/must be set/)
  end
end
