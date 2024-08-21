# frozen_string_literal: true

require "suma/biztime"

class Suma::Increase
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:increase) do
    setting :platform_account_id, "sandbox_account_id"
    setting :api_key, "test_increase_key"
    setting :host, "https://sandbox.increase.com"
    setting :app_url, "https://dashboard.increase.com"
  end

  def self.headers
    return {
      "Authorization" => "Bearer #{self.api_key}",
    }
  end

  def self.create_ach_route(id)
    response = Suma::Http.post(
      self.host + "/accounts/#{self.platform_account_id}/routes/achs",
      {name: id},
      headers: self.headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  def self.update_ach_route(ach_route_id, status: nil, name: nil)
    body = {}
    body[:status] = status if status
    body[:name] = name if name
    raise "Body cannot be empty" if body.blank?
    response = Suma::Http.execute(
      :patch,
      self.host + "/routes/achs/#{ach_route_id}",
      body:,
      headers: self.headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  def self._create_ach_transfer(account_number:, routing_number:, amount_cents:, memo:)
    body = {
      account_id: self.platform_account_id,
      account_number:,
      amount: amount_cents,
      routing_number:,
      statement_descriptor: memo,
    }
    response = Suma::Http.post(
      self.host + "/transfers/achs",
      body,
      headers: self.headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  def self.create_ach_credit_to_bank_account(bank_account, amount_cents:, memo:)
    raise Suma::InvalidPrecondition, "amount_cents cannot be negative" if amount_cents.negative?
    return self._create_ach_transfer(
      account_number: bank_account.account_number,
      routing_number: bank_account.routing_number,
      amount_cents:,
      memo:,
    )
  end

  def self.create_ach_debit_from_bank_account(bank_account, amount_cents:, memo:)
    raise Suma::InvalidPrecondition, "amount_cents cannot be negative" if amount_cents.negative?
    return self._create_ach_transfer(
      account_number: bank_account.account_number,
      routing_number: bank_account.routing_number,
      amount_cents: -amount_cents,
      memo:,
    )
  end

  def self.get_ach_transfer(id)
    response = Suma::Http.get(
      self.host + "/transfers/achs/#{id}",
      headers: self.headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  # Returns true if transfer's status is not in a pending or submitted state.
  def self.ach_transfer_failed?(ach_transfer_json)
    return [
      "pending_approval",
      "pending_submission",
      "submitted",
    ].none?(ach_transfer_json["status"])
  end

  # Returns true if transfer is submitted and
  # was created at least 5 business days before now in the member's timezone.
  def self.ach_transfer_succeeded?(ach_transfer_json, member_timezone:, now: Time.now)
    status = ach_transfer_json["status"]
    return false unless status == "submitted"
    cutoff = Suma::Biztime.roll_days(
      Suma::Payment::APPROXIMATE_ACH_SCHEDULE,
      Time.parse(ach_transfer_json["created_at"]).in_time_zone(member_timezone),
      days: 5,
    )
    return now > cutoff
  end
end
