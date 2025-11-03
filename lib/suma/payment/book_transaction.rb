# frozen_string_literal: true

require "suma/admin_linked"
require "suma/payment"

class Suma::Payment::BookTransaction < Suma::Postgres::Model(:payment_book_transactions)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked

  plugin :hybrid_search
  plugin :timestamps
  plugin :money_fields, :amount
  plugin :translated_text, :memo, Suma::TranslatedText

  many_to_one :originating_ledger, class: "Suma::Payment::Ledger"
  many_to_one :receiving_ledger, class: "Suma::Payment::Ledger"
  many_to_one :associated_vendor_service_category, class: "Suma::Vendor::ServiceCategory"
  one_to_one :originating_funding_transaction,
             class: "Suma::Payment::FundingTransaction",
             key: :originated_book_transaction_id
  one_to_one :originating_payout_transaction,
             class: "Suma::Payment::PayoutTransaction",
             key: :originated_book_transaction_id
  one_to_one :credited_payout_transaction,
             class: "Suma::Payment::PayoutTransaction",
             key: :crediting_book_transaction_id
  one_through_one :charge_contributed_to,
                  class: "Suma::Charge",
                  join_table: :charges_contributing_book_transactions,
                  right_key: :charge_id,
                  left_key: :book_transaction_id

  one_to_one :triggered_by,
             class: "Suma::Payment::Trigger::Execution"
  many_to_one :actor, class: "Suma::Member"

  def initialize(*)
    super
    self.opaque_id ||= Suma::Secureid.new_opaque_id("bx")
  end

  def rel_admin_link = "/book-transaction/#{self.id}"

  # Return a copy of the receiver, but with id removed, and amount set to be positive or negative
  # based on whether the receiver is the originating or receiving ledger.
  # This is used in places we need to represent book transactions
  # as ledger line items which have a directionality to them,
  # and we do not have a ledger as the time to determine directionality.
  #
  # The returned instance is frozen so cannot be saved/updated.
  def directed(relative_to_ledger)
    dup = self.values.dup
    case relative_to_ledger
      when self.originating_ledger
        dup[:amount_cents] *= -1
      when self.receiving_ledger
        nil
      else
        raise ArgumentError, "#{relative_to_ledger.inspect} is not associated with #{self.inspect}"
    end
    id = dup.delete(:id)
    inst = self.class.new(dup)
    inst.values[:_directed] = true
    inst.values[:id] = id
    inst.freeze
    return inst
  end

  # Return true if the received is an output of +directed+.
  def directed?
    return self.values.fetch(:_directed, false)
  end

  def debug_description
    return "BookTransaction[#{self.id}] for #{self.amount.format} from " \
           "#{self.originating_ledger.admin_label} to #{self.receiving_ledger.admin_label}"
  end

  UsageDetails = Struct.new(:code, :args)

  # @return [Array<UsageDetails>]
  def usage_details
    result = []
    if (ch = self.charge_contributed_to)
      code = "misc"
      service_name = self.memo.string
      if ch.mobility_trip
        code = "mobility_trip"
        service_name = ch.mobility_trip.vendor_service.external_name
      elsif ch.commerce_order
        code = "commerce_order"
        service_name = ch.commerce_order.checkout.cart.offering.description.string
      end
      result << UsageDetails.new(
        code, {
          discount_amount: Suma::Moneyutil.to_h(ch.discount_amount),
          service_name:,
        },
      )
    end

    if (fx = self.originating_funding_transaction)
      result << UsageDetails.new("funding", {account_label: fx.strategy.originating_instrument_label})
    elsif self.originating_payout_transaction
      result << UsageDetails.new("refund", {memo: self.memo.string})
    elsif self.credited_payout_transaction
      result << UsageDetails.new("credit", {memo: self.memo.string})
    end

    result << UsageDetails.new("unknown", {memo: self.memo.string}) if result.empty?
    return result
  end

  def hybrid_search_fields
    return [
      :opaque_id,
      ["Originating ledger", self.originating_ledger.admin_label],
      ["Receiving ledger", self.receiving_ledger.admin_label],
      :memo,
      :amount,
    ]
  end

  def validate
    super
    validate_self_referential_ledgers
  end

  private def validate_self_referential_ledgers
    return if self.receiving_ledger_id != self.originating_ledger_id
    circular_platform = Suma::Payment::Account.lookup_platform_account.id == self.receiving_ledger.account_id
    return if circular_platform
    self.errors.add(:receiving_ledger_id, "originating and receiving ledgers cannot be the same")
  end

  def before_create
    self.actor ||= self.class.current_actor
    super
  end

  def after_save
    super
    self.originating_ledger.clear_compound_associations if self.associations[:originating_ledger]
    self.receiving_ledger.clear_compound_associations if self.associations[:receiving_ledger]
  end

  # Return the current actor. If the action happened by request of an admin,
  # they are the actor. Otherwise the actor is the user making a request.
  # If the transaction was created outside of a request, such as through
  # a backend process, the actor is nil.
  # in that order. Nil means the transaction was not a part of a request.
  def self.current_actor
    user, admin = Suma.request_user_and_admin
    return admin unless admin.nil?
    return user unless user.nil?
    return nil
  end
end

# Table: payment_book_transactions
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                                    | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                            | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                            | timestamp with time zone |
#  apply_at                              | timestamp with time zone | NOT NULL
#  opaque_id                             | text                     | NOT NULL
#  originating_ledger_id                 | integer                  |
#  receiving_ledger_id                   | integer                  |
#  associated_vendor_service_category_id | integer                  |
#  amount_cents                          | integer                  | NOT NULL
#  amount_currency                       | text                     | NOT NULL
#  memo_id                               | integer                  | NOT NULL
#  actor_id                              | integer                  |
#  search_content                        | text                     |
#  search_embedding                      | vector(384)              |
#  search_hash                           | text                     |
# Indexes:
#  payment_book_transactions_pkey                          | PRIMARY KEY btree (id)
#  payment_book_transactions_originating_ledger_id_index   | btree (originating_ledger_id)
#  payment_book_transactions_receiving_ledger_id_index     | btree (receiving_ledger_id)
#  payment_book_transactions_search_content_tsvector_index | gin (to_tsvector('english'::regconfig, search_content))
# Check constraints:
#  amount_not_negative | (amount_cents >= 0)
# Foreign key constraints:
#  payment_book_transactions_actor_id_fkey                         | (actor_id) REFERENCES members(id) ON DELETE SET NULL
#  payment_book_transactions_associated_vendor_service_catego_fkey | (associated_vendor_service_category_id) REFERENCES vendor_service_categories(id)
#  payment_book_transactions_memo_id_fkey                          | (memo_id) REFERENCES translated_texts(id)
#  payment_book_transactions_originating_ledger_id_fkey            | (originating_ledger_id) REFERENCES payment_ledgers(id)
#  payment_book_transactions_receiving_ledger_id_fkey              | (receiving_ledger_id) REFERENCES payment_ledgers(id)
# Referenced By:
#  charge_line_items            | charge_line_items_book_transaction_id_fkey                      | (book_transaction_id) REFERENCES payment_book_transactions(id) ON DELETE RESTRICT
#  payment_funding_transactions | payment_funding_transactions_originated_book_transaction_i_fkey | (originated_book_transaction_id) REFERENCES payment_book_transactions(id) ON DELETE RESTRICT
#  payment_payout_transactions  | payment_payout_transactions_crediting_book_transaction_id_fkey  | (crediting_book_transaction_id) REFERENCES payment_book_transactions(id) ON DELETE RESTRICT
#  payment_payout_transactions  | payment_payout_transactions_originated_book_transaction_id_fkey | (originated_book_transaction_id) REFERENCES payment_book_transactions(id) ON DELETE RESTRICT
#  payment_trigger_executions   | payment_trigger_executions_book_transaction_id_fkey             | (book_transaction_id) REFERENCES payment_book_transactions(id)
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
