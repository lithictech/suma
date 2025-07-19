# frozen_string_literal: true

require "suma/spec_helpers"

module Suma::SpecHelpers::Message
  def self.included(context)
    context.before(:each) do |example|
      if example.metadata[:messaging]
        Suma::Message::Transport.registry_override = :fake
        Suma::Message::Transport::Fake.reset!
      end
    end

    context.after(:each) do |example|
      if example.metadata[:messaging]
        Suma::Message::Transport.registry_override = nil
        Suma::Message::Transport::Fake.reset!
      end
    end

    super
  end

  module_function def import_localized_message_seeds
    Suma::I18n::StaticStringIO.import_seeds(namespaces: Suma::Message::STATIC_STRING_NAMESPACE)
  end

  module_function def stub_signalwire_sms(opts={})
    opts[:fixture] ||= "signalwire/send_message"
    opts[:sid] ||= "SMABCDXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    opts[:status] ||= 200
    opts[:headers] ||= {}
    opts[:headers]["Content-Type"] = "application/json"

    if (body = opts[:body]).nil?
      body = load_fixture_data(opts[:fixture])
      body["sid"] = opts[:sid]
    end

    req = stub_request(:post, "https://sumafaketest.signalwire.com/2010-04-01/Accounts/sw-test-project/Messages.json")
    req = req.to_return(
      status: opts[:status],
      body: body.to_json,
      headers: opts[:headers],
    )
    return req
  end
end
