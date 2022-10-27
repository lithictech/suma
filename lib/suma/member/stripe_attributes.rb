# frozen_string_literal: true

require "suma/stripe"

# Implementation helper that gives members Stripe functionality.
class Suma::Member::StripeAttributes
  def initialize(member)
    @member = member
  end

  # Create a Stripe::Customer for the member, save its ID to the database, and return the Stripe object.
  # Fetch and return the Stripe::Customer if the member is already registered as a customer.
  #
  # https://stripe.com/docs/api#create_customer
  def register_as_customer
    return self.customer if self.registered_as_customer?

    identity_info = {
      email: @member.email,
      description: @member.name,
      metadata: Suma::Stripe.default_metadata.merge(suma_member_id: @member.id),
    }
    key = Suma.idempotency_key(@member, "customer")
    customer = Stripe::Customer.create(identity_info, idempotency_key: key)
    self.update_customer_json(customer)
    return customer
  end

  def registered_as_customer?
    return self.customer_id ? true : false
  end

  # Same as register_as_customer, but returns nothing if already registered.
  def ensure_registered_as_customer
    self.register_as_customer unless self.registered_as_customer?
  end

  # Return the Stripe::Customer for the member, or raise if not registered.
  def customer
    raise Suma::Stripe::CustomerNotRegistered unless self.registered_as_customer?
    return @customer ||= Stripe::Customer.construct_from(@member.stripe_customer_json.deep_symbolize_keys)
  end

  def update_customer_json(cust)
    @member.stripe_customer_json = cust.as_json
    @member.save_changes
  end

  def customer_id
    return @member.stripe_customer_json&.fetch("id", nil)
  end

  # Create a Stripe Card for the member's Stripe Customer and return it.
  # https://stripe.com/docs/api#create_card
  def register_card_for_charges(token_str)
    cust = self.customer
    key = Suma.idempotency_key(@member, "card", token_str)
    card = cust.sources.create({source: token_str}, idempotency_key: key)
    return card
  end

  def charge_card(card:, amount:, memo:, idempotency_key:, params: {}, metadata: {})
    raise Suma::InvalidPrecondition, "card owner must be member" unless card.member === @member
    metadata = Suma::Stripe.default_metadata.merge(
      {
        suma_card_id: card.id,
        suma_member_id: @member.id,
        suma_member_name: @member.name,
      },
      metadata,
    )
    return Stripe::Charge.create(
      {
        amount: amount.cents,
        currency: amount.currency,
        source: card.stripe_id,
        description: memo,
        customer: @member.stripe.customer_id,
        metadata:,
        **params,
      }, {
        idempotency_key:,
      },
    )
  end

  def update_card(card:, exp_month:, exp_year:)
    raise Suma::InvalidPrecondition, "card owner must be member" unless card.member === @member
    cust = Stripe::Customer.update_source(
      self.customer_id,
      card.stripe_id,
      {
        exp_month:,
        exp_year:,
      },
    )
    self.update_customer_json(cust)
  end
end
