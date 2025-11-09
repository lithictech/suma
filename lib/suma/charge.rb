# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

# Charges represent something a member was charged for,
# on or off platform. They are *not* part of the payment system;
# they are a higher-level representation of a charge,
# linked to something like a commerce order or mobility trip.
#
# Each charge may have one or more 'line items'.
# Each line item represents some part of the charge.
#
# Line items may represent on-platform funds flows (book transactions),
# like the money moved from each ledger to pay for an order
# that was paid from multiple ledgers (cash, subsidy, etc.).
#
# Line items may also represent off-platform funds flows,
# where there are no funds flows to represent. These are 'self'
# line items, which do not point to a book transaction
# (each line item can have 'self' data, or point to a book transaction).
# An example would be when we have a user account linked to
# an external vendor like Lyft, and Lyft handles all charging;
# suma is there as an intermediary but is not in the funds flow.
class Suma::Charge < Suma::Postgres::Model(:charges)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked

  plugin :hybrid_search
  plugin :timestamps
  plugin :money_fields, :undiscounted_subtotal, :off_platform_amount

  many_to_one :member, class: "Suma::Member"
  many_to_one :mobility_trip, class: "Suma::Mobility::Trip"
  many_to_one :commerce_order, class: "Suma::Commerce::Order"
  one_to_many :line_items, class: "Suma::Charge::LineItem", order: order_assoc(:asc)
  # Contributing book transactions are those which helped pay for the charge.
  # They should all originate from ledgers belonging to the charge's member.
  many_to_many :contributing_book_transactions,
               class: "Suma::Payment::BookTransaction",
               join_table: :charges_contributing_book_transactions,
               left_key: :charge_id,
               right_key: :book_transaction_id,
               order: order_desc
  # Keep track of any synchronous funding transactions
  # that were caused due to this charge. There is NOT a direct linkage
  # in ledgering terms- this is rather modeling the user experience
  # of when a charge and funding event happen one after the other
  # (ie, paying for an order during checkout, charges a card
  # to cover the difference).
  many_to_many :associated_funding_transactions,
               class: "Suma::Payment::FundingTransaction",
               join_table: :charges_associated_funding_transactions,
               left_key: :charge_id,
               right_key: :funding_transaction_id,
               order: order_desc

  def initialize(*)
    super
    self.opaque_id ||= Suma::Secureid.new_opaque_id("ch")
  end

  def discounted_subtotal = self.line_items.sum(Money.new(0), &:amount)
  def discount_amount = self.undiscounted_subtotal - self.discounted_subtotal

  # How much of the paid amount was synchronously funded during checkout?
  # Note that there is no crediting book transaction associated from the charge (which are all debits)
  # to the funding transaction (which is a credit)- payments work with ledgers, not linking
  # charges to orders, so we keep track of this additional data via associated_funding_transaction.
  def funded_amount = self.associated_funding_transactions.sum(Money.new(0), &:amount)

  # How much in cash did the user pay for this, either real-time or from a cash ledger credit.
  # Ie, how many of the book transactions for charges came from the cash ledger?
  def cash_paid_from_ledger = self.payment_group_amounts.fetch(:cash)

  # How much did the user send from ledgers that weren't the cash ledger?
  # This does NOT capture off-platform transactions ('self data' in charge line items),
  # so cash_paid + noncash_paid may not equal the paid_cost.
  def noncash_paid_from_ledger = self.payment_group_amounts.fetch(:noncash)

  # Return a hash of :cash and :noncash payment amounts.
  def payment_group_amounts
    cash_led = self.member.payment_account&.cash_ledger
    cash = Money.new(0)
    noncash = Money.new(0)
    self.contributing_book_transactions.each do |bx|
      if bx.originating_ledger === cash_led
        cash += bx.amount
      else
        noncash += bx.amount
      end
    end
    return {cash:, noncash:}
  end

  #
  # Use PricedItem aliases
  #

  alias undiscounted_cost undiscounted_subtotal
  alias customer_cost discounted_subtotal
  alias savings discount_amount

  def rel_admin_link = "/charge/#{self.id}"

  def add_line_item_from(has_amount_and_memo)
    self.add_line_item(amount: has_amount_and_memo.amount, memo: has_amount_and_memo.memo)
  end

  def hybrid_search_fields
    return [
      :opaque_id,
      :undiscounted_subtotal,
      :undiscounted_subtotal,
      :discount_amount,
      :member,
    ]
  end

  def hybrid_search_facts
    return [
      self.commerce_order && "I am for a commerce order.",
      self.mobility_trip && "I am for a mobility trip.",
    ]
  end
end

# Table: charges
# --------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                             | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                     | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                     | timestamp with time zone |
#  opaque_id                      | text                     | NOT NULL
#  undiscounted_subtotal_cents    | integer                  | NOT NULL
#  undiscounted_subtotal_currency | text                     | NOT NULL
#  member_id                      | integer                  | NOT NULL
#  mobility_trip_id               | integer                  |
#  commerce_order_id              | integer                  |
#  search_content                 | text                     |
#  search_embedding               | vector(384)              |
#  search_hash                    | text                     |
#  off_platform_amount_cents      | integer                  | NOT NULL DEFAULT 0
#  off_platform_amount_currency   | text                     | NOT NULL DEFAULT 'USD'::text
# Indexes:
#  charges_pkey                          | PRIMARY KEY btree (id)
#  charges_commerce_order_id_index       | UNIQUE btree (commerce_order_id) WHERE commerce_order_id IS NOT NULL
#  charges_mobility_trip_id_index        | UNIQUE btree (mobility_trip_id) WHERE mobility_trip_id IS NOT NULL
#  charges_member_id_index               | btree (member_id)
#  charges_search_content_trigram_index  | gist (search_content)
#  charges_search_content_tsvector_index | gin (to_tsvector('english'::regconfig, search_content))
# Check constraints:
#  associated_object_set | (commerce_order_id IS NOT NULL OR mobility_trip_id IS NOT NULL)
# Foreign key constraints:
#  charges_commerce_order_id_fkey | (commerce_order_id) REFERENCES commerce_orders(id) ON DELETE SET NULL
#  charges_member_id_fkey         | (member_id) REFERENCES members(id)
#  charges_mobility_trip_id_fkey  | (mobility_trip_id) REFERENCES mobility_trips(id) ON DELETE SET NULL
# Referenced By:
#  charge_line_items                       | charge_line_items_charge_id_fkey                       | (charge_id) REFERENCES charges(id) ON DELETE CASCADE
#  charges_associated_funding_transactions | charges_associated_funding_transactions_charge_id_fkey | (charge_id) REFERENCES charges(id)
#  charges_contributing_book_transactions  | charges_contributing_book_transactions_charge_id_fkey  | (charge_id) REFERENCES charges(id)
# --------------------------------------------------------------------------------------------------------------------------------------------------------
