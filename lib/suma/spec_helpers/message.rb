# frozen_string_literal: true

require "suma/spec_helpers"

module Suma::SpecHelpers::Message
  def self.included(context)
    context.before(:each) do |example|
      if example.metadata[:messaging]
        Suma::Message::Transport.override = :fake
        Suma::Message::FakeTransport.reset!
      end
    end

    context.after(:each) do |example|
      if example.metadata[:messaging]
        Suma::Message::Transport.override = nil
        Suma::Message::FakeTransport.reset!
      end
    end

    super
  end

  module_function def stub_twilio_sms(opts={})
    opts[:fixture] ||= "twilio/send_message"
    opts[:sid] ||= "SMABCDXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    opts[:status] ||= 200

    body = load_fixture_data(opts[:fixture])
    body["sid"] = opts[:sid]

    req = stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/AC444test/Messages.json")
    req = req.to_return(
      status: opts[:status],
      body: body.to_json,
      headers: opts[:headers],
    )
    return req
  end
end
