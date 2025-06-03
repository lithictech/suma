# frozen_string_literal: true

class Suma::AnonProxy::Relay::Signalwire < Suma::AnonProxy::Relay
  def key = "signalwire"
  def transport = :phone
  def webhookdb_table = Suma::Webhookdb.signalwire_messages_table

  def provision(member)
    query = URI.decode_www_form(Suma::Signalwire.phone_number_provision_query).to_h
    query[:max_results] = 1
    available = Suma::Signalwire.
      make_rest_request(:get, "/api/relay/rest/phone_numbers/search", query:).
      parsed_response
    raise Suma::InvariantViolation, "Signalwire returned no results" if available.fetch("data", []).empty?
    number = available["data"].first["e164"]
    purchased = Suma::Signalwire.make_rest_request(:post, "/api/relay/rest/phone_numbers", body: {number:})
    Suma::Signalwire.make_rest_request(
      :post,
      "/api/relay/rest/phone_numbers/#{purchased.fetch('id')}",
      body: {
        name: "AnonProxy - #{member.id}",
        message_handler: "laml_webhooks",
        message_request_url: Suma.api_url + "/v1/anon_proxy/relays/signalwire/webhooks",
        message_request_method: "POST",
        message_fallback_url: Suma.api_url + "/v1/anon_proxy/relays/signalwire/errors",
        message_fallback_method: "POST",
      },
    )
    return Suma::PhoneNumber::US.normalize(number)
  end

  def parse_message(row)
    return Suma::AnonProxy::ParsedMessage.new(
      message_id: row.fetch(:signalwire_id),
      to: Suma::PhoneNumber::US.normalize(row.fetch(:to)),
      from: Suma::PhoneNumber::US.normalize(row.fetch(:from)),
      content: row.fetch(:data).fetch("body"),
      timestamp: row.fetch(:date_created),
    )
  end
end
