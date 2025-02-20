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

  module_function def fetch_last_email
    old = WebMock::Config.instance.allow
    mpurl = Suma::Message::EmailTransport.mailpit_url
    getopts = {timeout: 5, logger: nil}
    WebMock::Config.instance.allow = mpurl
    begin
      list_resp = Suma::Http.get("#{mpurl}/api/v1/messages", {limit: 1}, **getopts)
      msg = list_resp.parsed_response.fetch("messages").first
      msgid = msg.fetch("ID")
      headers_resp = Suma::Http.get("#{mpurl}/api/v1/message/#{msgid}/headers", **getopts)
      msg["Headers"] = headers_resp.parsed_response
      return msg
    ensure
      WebMock::Config.instance.allow = old
    end
  end
end
