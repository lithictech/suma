# frozen_string_literal: true

require "appydays/loggable"
require "suma/lyft"
require "suma/mobility"
require "suma/mobility/trip_importer"

# Integrates with the Lyft Pass (Business) system.
# Can log into Lyft using the configured username, find the auth token in the sent email,
# then exchange it for an access code to hit the API.
# From the API, we find all rides taken for the configured program
class Suma::Lyft::Pass
  include Appydays::Loggable

  CREDENTIAL_SERVICE = "lyft-pass-access-token"
  # Credentials that expire before this far from now
  # should be thrown out for a new credential.
  EXPIRES_AT_FUZZ = 30.minutes

  PROGRAMS_CACHE_TTL = 30.minutes

  class << self
    def from_config
      return self.new(
        email: Suma::Lyft.pass_email,
        authorization: Suma::Lyft.pass_authorization,
        org_id: Suma::Lyft.pass_org_id,
      )
    end

    def programs_dataset = Suma::Program.exclude(lyft_pass_program_id: "")

    # Cache +programs_dataset+ for +PROGRAMS_CACHE_TTL+.
    # We use the list in certain app code that doesn't really fit with normal eager loading,
    # so this is sort of a gross work-around. Can adjust it in the future,
    # like if programs and AnonProxy get more tightly integrated.
    def programs_cached(now: Time.now)
      cached_at = Suma.cached_get("lyft-pass-programs-cached-at") { nil }
      if cached_at.nil? || cached_at < (now - PROGRAMS_CACHE_TTL)
        Suma.cached_set("lyft-pass-programs-cached-at", now)
        Suma.cached_set("lyft-pass-programs-cached", nil, delete: true)
      end
      return Suma.cached_get("lyft-pass-programs-cached") { self.programs_dataset.all }
    end
  end

  # After +authenticate+ is called, the credential will be a valid credential.
  # @return [Suma::ExternalCredential]
  attr_reader :credential

  # Email for the Business account.
  # It will be logged in remotely, it is suggested to create a separate user account for this programmatic access.
  attr_reader :email

  # This is the Authorization header value in Lyft requests.
  # Get from the browser console during the authentication flow.
  # It's like "Basic d0dldWh2RF5MNmNwOllicHpWdnN0Y2E1UW1NTWVlUVJ2dnI1ZUl0UTI5S1JR"
  attr_reader :authorization

  # The Lyft org ID.
  # Go to https://business.lyft.com/organization/mysumaorg/lyft-pass/transactions,
  # then look for the request to https://www.lyft.com/v1/enterprise-insights/search/transactions
  # in the console. Grab the organization id from the query params.
  attr_reader :org_id

  # Trips are associated with this vendor service.
  # @return [Suma::Vendor::Service]
  attr_reader :vendor_service

  # @return [Suma::Vendor::ServiceRate]
  attr_reader :vendor_service_rate

  def initialize(email:, authorization:, org_id:)
    raise ArgumentError, "email cannot be blank" if email.blank?
    raise ArgumentError, "authorization cannot be blank" if authorization.blank?
    raise ArgumentError, "org_id cannot be blank" if org_id.blank?
    @email = email
    @org_id = org_id
    # No idea what this actually is, if it changes, etc.
    @authorization = authorization
    @credential = nil
  end

  # @return [Suma::ExternalCredential,nil]
  def find_credential
    return Suma::ExternalCredential.
        where(service: CREDENTIAL_SERVICE).
        where { expires_at > Time.now + EXPIRES_AT_FUZZ }.
        first
  end

  # @return [Suma::ExternalCredential]
  def authenticate
    @credential = self.find_credential || self.authenticate!
    return @credential
  end

  def debug(_resp)
    # puts resp.headers, resp.body
  end

  # @return [Suma::ExternalCredential]
  def authenticate!
    auth_started_at = Time.now - 5.seconds # 5 seconds for clock drift
    # Arrive at the webpage that prompts for your email
    login_get_resp = Suma::Http.get("https://account.lyft.com/auth/email", logger: self.logger)
    self.debug(login_get_resp)
    session_id = extract_cookie(login_get_resp, "sessId")

    # The JS on the login page starts the oauth process and gets a short-lived auth code
    auth_code_resp = Suma::Http.post(
      "https://api.lyft.com/oauth2/access_token",
      {grant_type: "client_credentials"},
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Cookie" => "sessId=#{session_id}",
        "Authorization" => @authorization,
        "X-Authorization" => @authorization,
      },
      logger: self.logger,
    )
    self.debug(auth_code_resp)
    lyft_access_token_cookie = extract_cookie(auth_code_resp, "lyftAccessToken")
    browser_id_cookie = extract_cookie(auth_code_resp, "stickyLyftBrowserId")

    # Submit the form, which sends an email
    submit_email_form_resp = Suma::Http.post(
      "https://api.lyft.com/v1/email/login/request",
      {
        email: @email,
        next_url: "https://www.lyft.com/business/login?login_session_uuid=#{session_id}",
        login_session_uuid: session_id,
      },
      headers: {
        "Cookie" => encode_cookies(
          sessId: session_id,
          lyftAccessToken: lyft_access_token_cookie,
          NEXT_LOCALE: "en-US",
          stickyLyftBrowserId: browser_id_cookie,
        ),
      },
      logger: self.logger,
    )
    self.debug(submit_email_form_resp)

    # Wait a bit for the email to arrive
    seconds_to_wait = 120
    sleep_interval = 2
    attempts_remaining = seconds_to_wait / sleep_interval
    auth_email_row = loop do
      attempts_remaining -= 1
      row = Suma::Webhookdb.postmark_inbound_messages_dataset.
        where(from_email: "business@identity.lyftmail.com", to_email: @email).
        where(subject: "Here's your one-time Lyft Business log-in link").
        where { timestamp > auth_started_at }.
        order(:timestamp).
        last
      break row if row
      raise Suma::InvalidPostcondition, "lyft never sent the email" if attempts_remaining.zero?
      Kernel.sleep(sleep_interval)
      self.logger.debug("waiting_for_lyft_to_send_email", attempts_remaining:)
    end
    # login_link = %r{"(https://account\.lyft\.com/auth/email\?et=.*)" style}.match(auth_email_row[:data].fetch('HtmlBody'))[1]
    # Extract the 'email token' ('et' query param) from the magic link.
    email_html = auth_email_row[:data].fetch("HtmlBody")
    email_token = %r{"https://account\.lyft\.com/auth/email\?et=([\w%_-]+)[&;]}.match(email_html)[1]
    email_token = URI.decode_uri_component(email_token)

    # Use the email token, session id, browser id, and auth code to request a long-lived access token
    access_token_resp = Suma::Http.post(
      "https://api.lyft.com/oauth2/access_token",
      {
        grant_type: "urn:lyft:oauth2:grant_type:email",
        email_token:,
        login_session_uuid: session_id,
      },
      headers: {
        "Authorization" => @authorization,
        "X-Authorization" => @authorization,
        "Content-Type" => "application/x-www-form-urlencoded",
        "Cookie" => encode_cookies(
          sessId: session_id,
          lyftAccessToken: lyft_access_token_cookie,
          stickyLyftBrowserId: browser_id_cookie,
        ),
      },
      logger: self.logger,
    )
    self.debug(access_token_resp)
    access_token = extract_cookie(access_token_resp, "lyftAccessToken")
    data = {
      body: access_token_resp.parsed_response,
      cookies: {
        sessId: session_id,
        lyftAccessToken: access_token,
        stickyLyftBrowserId: browser_id_cookie,
      },
    }
    # noinspection RubyArgCount
    updated_credential = Suma::ExternalCredential.new(
      service: CREDENTIAL_SERVICE,
      expires_at: Time.now + access_token_resp.parsed_response.fetch("expires_in"),
      data: data.to_json,
    ).insert_conflict(
      target: :service,
      update: {
        expires_at: Sequel[:excluded][:expires_at],
        data: Sequel[:excluded][:data],
      },
    )
    updated_credential.save_changes
    @credential = updated_credential
    return updated_credential
  end

  def auth_headers
    raise Suma::InvalidPrecondition, "must call authenticate" if @credential.nil?
    data = JSON.parse(@credential.data)
    h = {
      "Cookie" => encode_cookies(data.fetch("cookies")),
      "Origin" => "https://business.lyft.com",
      "Referer" => "https://business.lyft.com",
    }
    return h
  end

  def fetch_rides(account_id)
    # TODO: We need to paginate the rides and stop when we find one we've already processed.
    # For now, assume we're not taking a page of rides (50) within a sync period (20 minutes).
    rides_resp = Suma::Http.post(
      "https://www.lyft.com/v1/enterprise-insights/search/transactions?organization_id=#{@org_id}&start_time=1546300800000",
      {
        "size" => 50,
        "next_token" => "",
        "aggs" => nil,
        "query" => {
          "bool" => {
            "must" => [
              {"nested" => {
                "path" => "transactions",
                "query" => {
                  "bool" => {
                    "should" => {
                      "terms" => {
                        "transactions.account_id" => [account_id],
                      },
                    },
                  },
                },
              }},
            ],
          },
        },
        "include" => [
          "enterprise_product_type",
          "transportation_id",
          "transportation_type",
          "transportation_sub_type",
          "transportation_mode",
          "transactions.amount",
          "transactions.currency",
          "transactions.id",
          "transactions.transaction_type",
          "transactions.txn_reporting_timestamp",
          "requested_at_iso",
          "requested_at_iso[utc_offset]",
          "canceled_at_iso",
          "picked_up_at_iso",
          "dropped_off_at_iso",
          "user_full_name",
        ],
        "sort" => [{"requested_at_utc" => {"order" => "desc"}}],
      },
      headers: self.auth_headers,
      logger: self.logger,
    )
    return rides_resp.parsed_response
  end

  def fetch_account_id_for_program_id(program_id)
    resp = Suma::Http.post(
      "https://www.lyft.com/api/rideprograms/ride-program",
      {ride_program_id: program_id},
      headers: self.auth_headers,
      logger: self.logger,
    )
    return resp.parsed_response.fetch("ride_program").fetch("owner").fetch("id")
  end

  def fetch_ride(tx_id)
    resp = Suma::Http.get(
      "https://www.lyft.com/v1/enterprise-insights/detail/transactions-legacy/#{tx_id}",
      headers: self.auth_headers,
      logger: self.logger,
    )
    return resp.parsed_response
  end

  def sync_trips_from_program(program)
    pricing = Suma::Enumerable.one!(program.pricings)
    self.sync_trips(pricing)
  end

  def sync_trips(pricing)
    program_id = pricing.program.lyft_pass_program_id
    raise Suma::InvalidPrecondition, "program must have lyft_pass_program_id set" if program_id.blank?
    self.with_log_tags(lyft_program_id: program_id) do
      account_id = self.fetch_account_id_for_program_id(program_id)
      self.with_log_tags(lyft_account_id: account_id) do
        rides = self.fetch_rides(account_id)
        tx_ids = rides.fetch("results").map { |r| r["transactions.id"] }
        tx_ids.each do |txid|
          self.with_log_tags(lyft_transaction_id: txid) do
            ride = self.fetch_ride(txid)
            self.upsert_ride_as_trip(ride, pricing)
          end
        end
      end
    end
  end

  VEHICLE_TYPES_FOR_RIDEABLE_TYPES = {
    "ELECTRIC_BIKE" => Suma::Mobility::EBIKE,
    "ELECTRIC_SCOOTER" => Suma::Mobility::ESCOOTER,
  }.freeze

  def upsert_ride_as_trip(ride_resp, pricing, check_dupes: true)
    vendor_service = pricing.vendor_service
    vendor_service_rate = pricing.vendor_service_rate
    ride = ride_resp.fetch("ride")
    rider_phone = ride.fetch("rider").fetch("phone_number")
    ride_id = ride.fetch("ride_id")
    receipt = Suma::Mobility::TripImporter::Receipt.new
    receipt.charged_at = Time.at(ride_resp.fetch("created_at_ms") / 1000)
    receipt.image_url = ride.fetch("map_image_url")
    receipt.trip.set(
      vehicle_id: ride_id,
      external_trip_id: ride_id,
      vehicle_type: VEHICLE_TYPES_FOR_RIDEABLE_TYPES.fetch(ride.fetch("rideable_type")),
      vendor_service:,
      vendor_service_rate:,
      began_at: Time.at(ride.fetch("pickup").fetch("timestamp_ms") / 1000),
      ended_at: Time.at(ride.fetch("dropoff").fetch("timestamp_ms") / 1000),
      begin_address: ride.fetch("pickup").fetch("address"),
      end_address: ride.fetch("dropoff").fetch("address"),
    )

    if (member = Suma::Member.with_normalized_phone(rider_phone.delete_prefix("+"))).nil?
      self.logger.warn("no_member_for_lyft_pass_rider", ride_id:, rider_phone:)
      Sentry.capture_message("No member for Lyft Pass ride") do |scope|
        scope.set_extras(
          rider_phone:,
          ride_id:,
          ride_resp: ride_resp.to_json,
        )
      end
      return nil
    end
    return nil if check_dupes && !Suma::Mobility::Trip.where(external_trip_id: ride_id).empty?

    receipt.trip.member = member

    # The "transaction amount". Will never be zero, since otherwise we wouldn't see it in our Lyft Pass.
    receipt.subsidized_off_platform_amount = _money2money(ride_resp)

    if receipt.subsidized_off_platform_amount.zero?
      msg = "transaction amount cannot be zero: #{ride_resp.to_json}"
      raise Suma::InvariantViolation, msg
    end

    # We cannot get useful information from the receipt line items,
    # since their memo/title can be in any language.
    #
    # Instead, let's make our own line items for the unlock fee, ride cost,
    # and a potential single item for other charges.
    #
    # Because suma's part of the ride cost is added as a subsidy,
    # we do NOT want to include it as a line item.
    # Instead, just ignore it entirely, so the outstanding balance on the receipt
    # is what suma paid via Lyft Pass PLUS what the member paid Lyft directly.
    #
    # If the of the non-promo line items EQUALS what we should charge based on rate alone,
    # no additional charges are needed.
    # If it is MORE than what we should charge based on rate alone,
    # add a single additional line item.
    #
    # If the of the non-promo line items is LESS than what we think we should charge based on rate alone,
    # alert in Sentry because something is wrong.
    # We can still create the receipt though, using a 'Lyft discount'
    # line item to match the difference adjustment.
    #
    receipt.unlock_fee = vendor_service_rate.surcharge
    receipt.per_minute_fee = vendor_service_rate.unit_amount
    credits_total = Money.new(0, receipt.subsidized_off_platform_amount.currency)
    debits_total = Money.new(0, receipt.subsidized_off_platform_amount.currency)
    seen_items = Set.new([])
    found_subsidy = false
    ride.fetch("line_items").each do |li|
      next if seen_items.include?(li)
      seen_items << li
      amount = _money2money(li)
      if -amount == receipt.subsidized_off_platform_amount
        found_subsidy = true
        next
      end
      if amount.positive?
        debits_total += amount
      else
        credits_total += -amount
        # Additional credits MUST show up as line items so we don't try to charge the user
        # the difference between our subsidy and what they paid.
        # We cannot itemize charges (since we don't know how to find the ride/unlock charge to replace with our own),
        # but we CAN itemize credits, since we aren't adding any of our own
        # (the lyft pass portion is handled as a subsidy).
        receipt.misc_line_items << Suma::Mobility::EndTripResult::LineItem.new(
          amount:,
          memo: Suma::TranslatedText.new(all: li.fetch("title")),
        )
      end
    end
    unless found_subsidy
      msg = "transaction amount not found in Lyft Pass line items: #{ride_resp.to_json}"
      raise Suma::InvariantViolation, msg
    end

    receipt.paid_off_platform_amount = debits_total - credits_total - receipt.subsidized_off_platform_amount
    calculated_cost = vendor_service_rate.calculate_total(receipt.trip.duration_minutes)
    additional_charges = debits_total - calculated_cost
    if additional_charges.zero?
      # The ride cost exactly what we expect, do not create an additional line item.
    elsif additional_charges.positive?
      receipt.misc_line_items << Suma::Mobility::EndTripResult::LineItem.new(
        amount: additional_charges,
        memo: Suma::I18n::StaticString.find_text("backend", "trip_receipt_additional_charges"),
      )
    else
      Sentry.capture_message("Lyft Pass charge total less than expected") do |scope|
        scope.set_extras(
          member_id: receipt.trip.member_id,
          member_name: receipt.trip.member.name,
          external_trip_id: receipt.trip.external_trip_id,
          rate_id: receipt.trip.vendor_service_rate.id,
          ride_resp: ride_resp.to_json,
        )
      end
      receipt.misc_line_items << Suma::Mobility::EndTripResult::LineItem.new(
        amount: additional_charges,
        memo: Suma::I18n::StaticString.find_text("backend", "trip_receipt_additional_discount").
          format(vendor: "Lyft"),
      )
    end

    # Undiscounted subtotal is calculated by us, PLUS any uncategorized items like parking fees.
    # Do NOT include credits in the undiscounted amount- it's not sure what they are,
    # and we err on the side of more savings.
    receipt.undiscounted_subtotal = vendor_service_rate.calculate_undiscounted_total(receipt.trip.duration_minutes)
    receipt.misc_line_items.each do |li|
      receipt.undiscounted_subtotal += li.amount if li.amount.positive?
    end

    Suma::Mobility::TripImporter.import(receipt:, program: pricing.program, logger: self.logger)
    return receipt.trip.new? ? nil : receipt.trip
  end

  def invite_member(member, program_id:)
    self.logger.info "inviting_lyft_pass", member_id: member.id, lyft_program_id: program_id, phone: member.phone
    Suma::Http.post(
      "https://www.lyft.com/api/rideprograms/enrollment/bulk/invite",
      {
        enrollment_users: [
          {
            custom_field_value_key_value_pairs: [],
            user_identifier: {
              phone_number: Suma::PhoneNumber.format_e164(member.phone),
            },
          },
        ],
        ride_program_id: program_id,
      },
      headers: self.auth_headers,
      logger: self.logger,
    )
  end

  # Revoke the member's access to Lyft Pass.
  # @param [String] phone If given, use this as the phone instead of member.phone.
  #   Useful when a member is deleted and its current phone is a placeholder.
  def revoke_member(member, program_id:, phone: member.phone)
    self.logger.info "revoking_lyft_pass", member_id: member.id, lyft_program_id: program_id, phone:
    Suma::Http.post(
      "https://www.lyft.com/api/rideprograms/enrollment/revoke",
      {
        ride_program_id: program_id,
        user_identifier: {
          phone_number: Suma::PhoneNumber.format_e164(phone),
        },
      },
      headers: self.auth_headers,
      logger: self.logger,
    )
  end

  def _money2money(h)
    money = h.fetch("money")
    return Money.new(money.fetch("amount"), money.fetch("currency"))
  end

  def extract_cookie(resp, key)
    return %r{#{key}=([\w\-/\+\=]+);}.match(resp.headers["Set-Cookie"])[1]
  end

  def encode_cookies(h)
    return h.map { |k, v| "#{k}=#{v}" }.join("; ")
  end
end
