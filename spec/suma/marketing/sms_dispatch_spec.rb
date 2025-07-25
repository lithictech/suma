# frozen_string_literal: true

RSpec.describe "Suma::Marketing::SmsDispatch", :db do
  let(:described_class) { Suma::Marketing::SmsDispatch }

  it "has members and broadcasts associations" do
    sms_broadcast = Suma::Fixtures.marketing_sms_broadcast.create
    member = Suma::Fixtures.member.create
    d = Suma::Fixtures.marketing_sms_dispatch.create(member:, sms_broadcast:)
    expect(d.member).to be === member
    expect(member.marketing_sms_dispatches).to contain_exactly(be === d)
    expect(d.sms_broadcast).to be === sms_broadcast
    expect(sms_broadcast.sms_dispatches).to contain_exactly(be === d)
  end

  describe "validations" do
    it "requires transport message id and sent_at to be both sent or unsent" do
      inst = Suma::Fixtures.marketing_sms_dispatch.create
      expect { inst.update(transport_message_id: "x") }.to raise_error(/violates check constraint/)
      inst.refresh
      expect { inst.update(sent_at: Time.now) }.to raise_error(/violates check constraint/)
      inst.refresh
      expect { inst.update(sent_at: Time.now, transport_message_id: "x") }.to_not raise_error
    end
  end

  describe "status" do
    let(:o) { Suma::Fixtures.marketing_sms_dispatch.instance }

    it "can be pending, sent, and canceled" do
      expect(o).to have_attributes(status: :pending)
      o.cancel
      expect(o).to have_attributes(status: :canceled)
      o.set_sent("x")
      expect(o).to have_attributes(status: :sent)
    end

    it "is canceled when sent and transport message id is blank" do
      expect(o).to_not be_canceled
      o.cancel
      expect(o).to have_attributes(
        sent_at: match_time(:now),
        transport_message_id: "",
      )
      expect(o).to be_canceled
    end

    it "clears last_error on successful send" do
      o.last_error = "ooops"
      o.set_sent("x")
      expect(o).to have_attributes(last_error: nil)
    end
  end

  describe "sending dispatches", :no_transaction_check, reset_configuration: Suma::Signalwire do
    before(:each) do
      Suma::Signalwire.marketing_number = "12223334444"
    end

    it "sends the SMS through Signalwire using the member's preferred language" do
      en = Suma::Fixtures.member.with_preferences(preferred_language: "en").create(phone: "15556667777", name: "Eng")
      es = Suma::Fixtures.member.with_preferences(preferred_language: "es").create(phone: "15556669999", name: "Esp")
      sms_broadcast = Suma::Fixtures.marketing_sms_broadcast.with_body("hi {{name}}", "hola {{name}}").create

      d_en = Suma::Fixtures.marketing_sms_dispatch.create(sms_broadcast:, member: en)
      d_es = Suma::Fixtures.marketing_sms_dispatch.create(sms_broadcast:, member: es)
      # this is already sent so will be skipped
      d_sent = Suma::Fixtures.marketing_sms_dispatch.sent.create
      req_en = stub_request(:post, "https://sumafaketest.signalwire.com/2010-04-01/Accounts/sw-test-project/Messages.json").
        with(body: {"Body" => "hi Eng", "From" => "+12223334444", "To" => "+15556667777"}).
        to_return(json_response(load_fixture_data("signalwire/send_message")))
      req_es = stub_request(:post, "https://sumafaketest.signalwire.com/2010-04-01/Accounts/sw-test-project/Messages.json").
        with(body: {"Body" => "hola Esp", "From" => "+12223334444", "To" => "+15556669999"}).
        to_return(json_response(load_fixture_data("signalwire/send_message")))

      described_class.send_all
      expect(req_en).to have_been_made
      expect(req_es).to have_been_made

      expect(d_en.refresh).to have_attributes(
        sent?: true,
        transport_message_id: "SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      )
      expect(d_es.refresh).to have_attributes(
        sent?: true,
        transport_message_id: "SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      )
    end

    it "cancels dispatches if the marketing number is not set" do
      Suma::Signalwire.marketing_number = ""
      d = Suma::Fixtures.marketing_sms_dispatch.create
      described_class.send_all
      expect(d.refresh).to be_canceled
    end

    it "handles errors by sending them to Sentry and moving on" do
      disp = Suma::Fixtures.marketing_sms_dispatch.create
      req = stub_request(:post, "https://sumafaketest.signalwire.com/2010-04-01/Accounts/sw-test-project/Messages.json").
        to_return(
          json_response(load_fixture_data("signalwire/error_internal").merge("code" => "123"), status: 400),
        )
      expect(Sentry).to receive(:capture_exception).with(any_args) do |e|
        expect(e).to be_a(Twilio::REST::RestError)
        expect(e.to_s).to include("Unable to create record")
      end

      described_class.send_all
      expect(req).to have_been_made

      expect(disp.refresh).to have_attributes(
        sent?: false,
        transport_message_id: nil,
      )
    end

    it "cancels if the body is empty" do
      disp = Suma::Fixtures.marketing_sms_dispatch.create
      disp.sms_broadcast.body.update(en: "")
      described_class.send_all
      expect(disp.refresh).to be_canceled
    end
  end

  describe "external links" do
    it "points to Signalwire" do
      d = Suma::Fixtures.marketing_sms_dispatch.create
      expect(d.external_links).to be_empty
      d.transport_message_id = "abc"
      expect(d.external_links).to contain_exactly(
        have_attributes(name: "Signalwire Message", url: "https://sumafaketest.signalwire.com/logs/messages/abc"),
      )
    end
  end
end
