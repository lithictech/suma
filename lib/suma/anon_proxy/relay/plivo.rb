# frozen_string_literal: true

require "suma/plivo"

class Suma::AnonProxy::Relay::Plivo < Suma::AnonProxy::Relay
  class PendingPhonePurchase < StandardError; end

  def key = "plivo"
  def transport = :sms
  def webhookdb_table = Suma::Webhookdb.plivo_sms_table

  def provision(member)
    # We'll need a way to localize SMS anon proxy to country.
    # In the meantime, this is US-only.
    search_response = Suma::Plivo.request(
      :get,
      "/PhoneNumber",
      query: {country_iso: "US", limit: "1", services: "sms"},
    )
    number = search_response["objects"].first
    buy_resp = Suma::Plivo.request(
      :post,
      "/PhoneNumber/#{number['number']}",
      body: {app_id: Suma::Plivo.anon_proxy_number_app_id},
    )
    num = buy_resp["numbers"].first
    Suma::Plivo.logger.info "plivo_provisioned", member_id: member.id, phone: num["number"], status: num["status"]
    if num["status"] == "pending"
      msg = "Phone number #{num['number']} for #{member.id} is pending: #{buy_resp}"
      raise PendingPhonePurchase, msg
    end
    return num["number"]
  end

  def parse_message(row)
    return Suma::AnonProxy::ParsedMessage.new(
      message_id: row.fetch(:plivo_message_uuid),
      to: row.fetch(:to_number),
      from: row.fetch(:from_number),
      content: row.fetch(:data).fetch("Text"),
      timestamp: row.fetch(:message_time),
    )
  end

  def lookup_member(to)
    m = Suma::AnonProxy::MemberContact[phone: to]
    return m if m
    raise Suma::InvalidPostcondition, "no MemberContact associated with phone #{to}"
  end
end
