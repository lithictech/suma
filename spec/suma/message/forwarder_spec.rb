# frozen_string_literal: true

require "suma/message/forwarder"

RSpec.describe Suma::Message::Forwarder, :db, :no_transaction_check, reset_configuration: Suma::Message::Forwarder do
  before(:each) do
    Suma::Message::Forwarder.phone_numbers = ["15552223333", "+12224445555"]
    Suma::Message::Forwarder.front_inbox_id = "1234"
  end

  let(:june14) { Time.at(1_749_921_156) }

  def messagerow(swid, data={})
    data[:to] ||= Suma::PhoneNumber.format_e164(Suma::Message::Forwarder.phone_numbers.sample)
    data[:from] ||= "+14445551234"
    data[:date_created] ||= june14
    data[:num_media] ||= 0
    r = {
      signalwire_id: swid,
      date_created: data[:date_created],
      direction: "inbound",
      from: data[:from],
      to: data[:to],
      data: data.to_json,
    }
    return r
  end

  def insert_message(swid, data={}) = Suma::Webhookdb.signalwire_messages_dataset.insert(messagerow(swid, data))

  it "syncs recent messages sent to the configured numbers into the configured Front inbox" do
    old = insert_message("msg2", date_created: june14 - 8.days)
    wrong_to = insert_message("msg3", to: "+13334445555")
    msg1 = insert_message("msg1", body: "hello")

    req = stub_request(:post, "https://api2.frontapp.com/inboxes/inb_ya/imported_messages").
      with(body: {
        sender: {handle: "alt:phone:+14445551234"},
        to: ["alt:phone:+14445551234"],
        body: "hello",
        external_id: "msg1",
        created_at: 1_749_921_156,
        type: "sms",
        metadata: {is_inbound: true, is_archived: false},
        attachments: [],
      }.to_json).to_return(json_response({}))

    described_class.new(now: june14).run
    expect(req).to have_been_made
  end

  it "is idempotent" do
    insert_message("msg1", body: "hello")
    req = stub_request(:post, "https://api2.frontapp.com/inboxes/inb_ya/imported_messages").
      to_return(json_response({}))

    described_class.new(now: june14).run
    described_class.new(now: june14).run
    expect(req).to have_been_made.once
  end

  it "includes media" do
    msg = insert_message(
      "msg1",
      body: "hello",
      num_media: 3,
      subresource_uris: {
        media: "/api/laml/2010-04-01/Accounts/AC123/Messages/msg1/Media.json",
      },
    )

    media_list_req = stub_request(:get, "https://sumafaketest.signalwire.com/api/laml/2010-04-01/Accounts/AC123/Messages/msg1/Media.json").
      to_return(
        json_response(
          {
            media_list: [
              {
                sid: "media1",
                content_type: "image/jpeg",
                uri: "/api/laml/2010-04-01/Accounts/AC123/Messages/SMabcxyz/Media/media1.json",
              },
              {
                sid: "media2",
                content_type: "video/mp4",
                uri: "/api/laml/2010-04-01/Accounts/AC123/Messages/SMabcxyz/Media/media2.json",
              },
              {
                sid: "media3",
                # Unrecognized content type should have .unrek extension but octet-stream mimetype
                content_type: "image/unrek",
                uri: "/api/laml/2010-04-01/Accounts/AC123/Messages/SMabcxyz/Media/media3.json",
              },
            ],
          },
        ),
      )
    media1_req = stub_request(:get, "https://sumafaketest.signalwire.com/api/laml/2010-04-01/Accounts/AC123/Messages/SMabcxyz/Media/media1").
      to_return(status: 200, body: "media1 body", headers: {"Content-Type" => "image/jpeg"})
    media2_req = stub_request(:get, "https://sumafaketest.signalwire.com/api/laml/2010-04-01/Accounts/AC123/Messages/SMabcxyz/Media/media2").
      to_return(status: 200, body: "media2 body", headers: {"Content-Type" => "video/mp4"})
    media3_req = stub_request(:get, "https://sumafaketest.signalwire.com/api/laml/2010-04-01/Accounts/AC123/Messages/SMabcxyz/Media/media3").
      to_return(status: 200, body: "media3 body", headers: {"Content-Type" => "image/unrek"})

    # rubocop:disable Layout/LineLength
    front_req = stub_request(:post, "https://api2.frontapp.com/inboxes/inb_ya/imported_messages").
      with do |req|
      expect(req.body).to include("Content-Disposition: form-data; name=\"external_id\"\r\n\r\nmsg1")
      expect(req.body).to include("Content-Disposition: form-data; name=\"metadata[is_inbound]\"\r\n\r\ntrue")
      expect(req.body).to include("Content-Disposition: form-data; name=\"attachments[0]\"; filename=\"20250614-attachment1.jpeg\"\r\nContent-Type: image/jpeg\r\n\r\nmedia1 body")
      expect(req.body).to include("Content-Disposition: form-data; name=\"attachments[1]\"; filename=\"20250614-attachment2.mp4\"\r\nContent-Type: application/mp4\r\n\r\nmedia2 body")
      expect(req.body).to include("Content-Disposition: form-data; name=\"attachments[2]\"; filename=\"20250614-attachment3.unrek\"\r\nContent-Type: application/octet-stream\r\n\r\nmedia3 body")
    end.to_return(json_response({message_uid: "FMID2"}, status: 202))
    # rubocop:enable Layout/LineLength

    described_class.new(now: june14).run
    expect(media_list_req).to have_been_made
    expect(media1_req).to have_been_made
    expect(media2_req).to have_been_made
    expect(media3_req).to have_been_made
    expect(front_req).to have_been_made
  end

  it "errors if the Front inbox is not set" do
    described_class.front_inbox_id = ""
    expect do
      described_class.new(now: june14).run
    end.to raise_error(/must be set/)
  end
end
