# frozen_string_literal: true

require "suma/admin_linked"
require "suma/external_links"
require "suma/payment/instrument"
require "suma/postgres/model"

class Suma::Payment::Card < Suma::Postgres::Model(:payment_cards)
  include Suma::Payment::Instrument
  include Suma::AdminLinked
  include Suma::ExternalLinks

  plugin :timestamps
  plugin :soft_deletes

  many_to_one :legal_entity, class: "Suma::LegalEntity"
  one_through_many :member,
                   [
                     [:legal_entities, :id, :id],
                     [:members, :legal_entity_id, :id],
                   ],
                   class: "Suma::Member",
                   left_primary_key: :legal_entity_id

  dataset_module do
    def usable
      return self.not_soft_deleted
    end
  end

  def payment_method_type
    return "card"
  end

  def can_use_for_funding?
    return true
  end

  def rel_admin_link = "/card/#{self.id}"

  def institution
    inst = INSTITUTIONS[self.brand]
    inst ||= Institution.new(
      name: self.brand,
      logo: DEFAULT_INSTITUTION.logo,
      color: DEFAULT_INSTITUTION.color,
    )
    return inst
  end

  def last4
    return self.helcim_json.fetch("cardNumber")[-4..]
  end

  def brand
    return self.helcim_json.fetch("cardType")
  end

  def helcim_token
    return self.helcim_json.fetch("cardToken")
  end

  def name
    return "#{self.brand} x-#{self.last4}"
  end

  INSTITUTIONS = {
    "Visa" => Institution.new(
      name: "Visa",
      logo: Base64.strict_encode64(File.binread(Suma::DATA_DIR + "payment-icons/visa.png")),
      color: "#1A1F71",
    ),
    "MasterCard" => Institution.new(
      name: "MasterCard",
      logo: Base64.strict_encode64(File.binread(Suma::DATA_DIR + "payment-icons/mastercard.png")),
      color: "#EB001B",
    ),
  }.freeze
  DEFAULT_INSTITUTION = Institution.new(
    name: "",
    logo: Base64.strict_encode64(File.binread(Suma::DATA_DIR + "payment-icons/default.png")),
    color: "#AAAAAA",
  )
end
