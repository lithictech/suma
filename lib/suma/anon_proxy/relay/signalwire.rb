# frozen_string_literal: true

require "suma/async/anon_proxy_member_contact_destroyed_resource_cleanup"

class Suma::AnonProxy::Relay::Signalwire < Suma::AnonProxy::Relay
  def key = "signalwire"
  def transport = :phone
  def webhookdb_dataset = Suma::Webhookdb.signalwire_messages_dataset.where(direction: "inbound")

  def provision(member)
    raise Suma::InvalidPrecondition, "Member[#{member.id}] phone #{member.phone} is not in the SMS_ALLOWLIST" unless
      Suma::Message::Transport::Sms.allowlisted_phone?(member.phone)
    query = URI.decode_www_form(Suma::Signalwire.phone_number_provision_query).to_h
    query[:max_results] = 1
    available = Suma::Signalwire.
      make_rest_request(:get, "/api/relay/rest/phone_numbers/search", query:).
      parsed_response
    raise Suma::InvariantViolation, "Signalwire returned no results" if available.fetch("data", []).empty?
    number = available["data"].first["e164"]
    purchased = Suma::Signalwire.make_rest_request(:post, "/api/relay/rest/phone_numbers", body: {number:})
    external_id = purchased.fetch("id")
    environ = Suma::RACK_ENV == "production" ? "" : "(#{Suma::RACK_ENV}) "
    Suma::Signalwire.make_rest_request(
      :put,
      "/api/relay/rest/phone_numbers/#{external_id}",
      body: {
        name: "#{environ}AnonProxy - #{member.id}",
        message_handler: "laml_webhooks",
        message_request_url: Suma.api_url + "/v1/anon_proxy/relays/signalwire/webhooks",
        message_request_method: "POST",
        message_fallback_url: Suma.api_url + "/v1/anon_proxy/relays/signalwire/errors",
        message_fallback_method: "POST",
      },
    )
    address = Suma::PhoneNumber::US.normalize(number)
    return ProvisionedAddress.new(address, external_id:)
  end

  def deprovision(addr)
    Suma::Signalwire.make_rest_request(:delete, "/api/relay/rest/phone_numbers/#{addr.external_id}")
    return nil
  rescue Suma::Http::Error => e
    return nil if e.status == 404
    return nil if self._handle_rescheduled_delete(e, addr)
    raise e
  end

  def _handle_rescheduled_delete(e, addr)
    return false if e.status != 422
    errors = e.response.parsed_response["errors"]
    return false if errors.blank?
    msg = errors.first.fetch("detail", "")
    return false unless msg.include?("Number was purchased too recently to release")
    can_release_at_re = /until (?<t>\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d UTC) to/.match(msg)
    raise Suma::InvariantViolation, "unexpected Signalwire error, could not parse date: #{msg}" if
      can_release_at_re.nil?
    schedule_at = Time.parse(can_release_at_re["t"]) + 1.hour
    Suma::Async::AnonProxyMemberContactDestroyedResourceCleanup.
      perform_at(schedule_at, {address: addr.address, external_id: addr.external_id, relay_key: self.key})
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

  def external_links(member_contact)
    phone_id = member_contact.external_relay_id
    return [
      {name: "Signalwire", url: "https://#{Suma::Signalwire.space_url}/phone_numbers/#{phone_id}"},
    ]
  end
end
