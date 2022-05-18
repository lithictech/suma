# frozen_string_literal: true

require "suma/http"
require "suma/plaid"
require "suma/postgres/model"

class Suma::PlaidInstitution < Suma::Postgres::Model(:plaid_institutions)
  plugin :timestamps

  def self.update_all
    offset = 0
    loop do
      resp = Suma::Http.post(
        Suma::Plaid.host + "/institutions/get",
        {
          client_id: Suma::Plaid.client_id,
          secret: Suma::Plaid.secret,
          count: 50,
          offset:,
          country_codes: Suma::Plaid.supported_country_codes,
          options: {include_optional_metadata: true},
        },
        logger: self.logger,
      )
      return if resp.parsed_response["institutions"].blank?
      resp.parsed_response["institutions"].each do |inst|
        Suma::PlaidInstitution.update_or_create(
          {institution_id: inst["institution_id"]},
          {
            name: inst["name"],
            logo_base64: inst["logo"] || "",
            primary_color_hex: inst["primary_color"] || "#000000",
            routing_numbers: inst["routing_numbers"] || [],
            data: inst["to_json"] || "{}",
          },
        )
        sleep(Suma::Plaid.bulk_sync_sleep) if Suma::Plaid.bulk_sync_sleep
      end
      offset += 50
    end
  end
end
