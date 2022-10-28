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

  def stripe_id = self.stripe_json.fetch("id")
  def last4  = self.stripe_json.fetch("last4")
  def brand  = self.stripe_json.fetch("brand")
  def name = "#{self.brand} x-#{self.last4}"

  def stripe_card
    return @stripe_card ||= Stripe::Card.construct_from(stripe_json.deep_symbolize_keys)
  end

  def _external_links_self
    return [
      self._external_link(
        "Stripe Customer",
        "#{Suma::Stripe.app_url}/customers/#{self.stripe_json.fetch('customer')}",
      ),
    ]
  end

  def self.load_payment_icon_base64(name)
    b = Base64.strict_encode64(File.binread(Suma::DATA_DIR + "payment-icons/#{name}"))
    return "data:image/png;base64,#{b}"
  end

  INSTITUTIONS = {
    "Visa" => Institution.new(
      name: "Visa",
      logo: self.load_payment_icon_base64("visa.png"),
      color: "#1A1F71",
    ),
    "MasterCard" => Institution.new(
      name: "MasterCard",
      logo: self.load_payment_icon_base64("mastercard.png"),
      color: "#EB001B",
    ),
  }.freeze
  DEFAULT_INSTITUTION = Institution.new(
    name: "",
    logo: self.load_payment_icon_base64("default.png"),
    color: "#AAAAAA",
  )
end
