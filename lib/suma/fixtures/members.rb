# frozen_string_literal: true

require "faker"
require "securerandom"

require "suma"
require "suma/fixtures"
require "suma/member"

module Suma::Fixtures::Members
  extend Suma::Fixtures

  PASSWORD = "suma1234"

  fixtured_class Suma::Member

  base :member do
    self.name ||= Faker::Name.name
    self.email ||= Faker::Internet.email
    self.phone ||= Faker::Suma.us_phone
    self.password_digest ||= Suma::Member::PLACEHOLDER_PASSWORD_DIGEST
  end

  before_saving do |instance|
    instance
  end

  decorator :password do |pwd=nil|
    pwd ||= PASSWORD
    self.password = pwd
  end

  decorator :plus_sign do |part=nil|
    part ||= SecureRandom.hex(8)
    local, domain = self.email.split("@")
    self.email = "#{local}+#{part}@#{domain}"
  end

  decorator :admin, presave: true do
    self.add_role(Suma::Role.admin_role)
  end

  decorator :with_role, presave: true do |role|
    role ||= Faker::Lorem.word
    role = Suma::Role.find_or_create(name: role) if role.is_a?(String)
    self.add_role(role)
  end

  decorator :with_dob do
    self.dob = Faker::Date.birthday
  end

  decorator :with_email do |username=nil|
    self.email = (username || Faker::Internet.username) + "@example.com"
  end

  decorator :with_phone, presave: true do |phone=nil|
    self.phone = phone || Faker::PhoneNumber.cell_phone
  end

  decorator :with_legal_entity do |opts={}|
    opts = Suma::Fixtures.legal_entity.create(opts) unless opts.is_a?(Suma::LegalEntity)
    self.legal_entity = opts
  end

  decorator :link_legal_entity, presave: true do |opts={}|
    opts = Suma::Fixtures.legal_entity.create(opts) unless opts.is_a?(Suma::LegalEntity)
    self.add_linked_legal_entity(opts)
  end

  decorator :onboarding_verified do |t=Time.now|
    self.onboarding_verified_at = t
  end

  decorator :with_cash_ledger, presave: true do |amount: nil|
    led = Suma::Payment.ensure_cash_ledger(self)
    Suma::Fixtures.book_transaction.to(led).create(amount:) if amount
  end

  decorator :terms_agreed do
    self.terms_agreed = Suma::Member::LATEST_TERMS_PUBLISH_DATE
  end

  decorator :registered_as_stripe_customer, presave: true do |json=nil|
    if json.nil?
      json = STRIPE_JSON.dup
      json["id"] = "cus_fixtured_#{SecureRandom.hex(8)}"
    end
    self.update(stripe_customer_json: json)
  end

  def self.register_as_stripe_customer(member)
    return member if member.stripe_customer_json.present?
    member.stripe_customer_json = STRIPE_JSON.dup
    return member.save_changes
  end

  STRIPE_JSON = {
    "id" => "cus_xyz",
    "object" => "customer",
    "account_balance" => 0,
    "created" => 1_529_818_867,
    "currency" => "usd",
    "default_source" => nil,
    "delinquent" => false,
    "description" => nil,
    "discount" => nil,
    "email" => nil,
    "invoice_prefix" => "A6D2E24",
    "livemode" => false,
    "metadata" => {},
    "shipping" => nil,
    "sources" => {
      "object" => "list",
      "data" => [],
      "has_more" => false,
      "total_count" => 0,
      "url" => "/v1/customers/cus_D6eGmbqyejk8s9/sources",
    },
    "subscriptions" => {
      "object" => "list",
      "data" => [],
      "has_more" => false,
      "total_count" => 0,
      "url" => "/v1/customers/cus_D6eGmbqyejk8s9/subscriptions",
    },
  }.freeze
end
