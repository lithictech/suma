# frozen_string_literal: true

require "suma/admin_linked"
require "suma/payment"

class Suma::Payment::Ledger < Suma::Postgres::Model(:payment_ledgers)
  include Suma::AdminLinked

  plugin :timestamps
  plugin :translated_text, :contribution_text, Suma::TranslatedText

  def self.combined_dataset_sorter(ledger_ids)
    return [
      Sequel.desc(:apply_at),
      Sequel.desc(Sequel.case({Sequel[originating_ledger_id: ledger_ids] => 1}, 0)),
      Sequel.asc(:id),
    ]
  end

  many_to_one :account, class: "Suma::Payment::Account"
  many_to_many :vendor_service_categories,
               class: "Suma::Vendor::ServiceCategory",
               join_table: :vendor_service_categories_payment_ledgers,
               left_key: :ledger_id,
               right_key: :category_id
  one_to_many :originated_book_transactions, class: "Suma::Payment::BookTransaction", key: :originating_ledger_id
  one_to_many :received_book_transactions, class: "Suma::Payment::BookTransaction", key: :receiving_ledger_id
  one_to_many :combined_book_transactions,
              class: "Suma::Payment::BookTransaction",
              readonly: true,
              eager_loader: (lambda do |eo|
                # Custom eager loader because we need to check 2 FKs for an ID, not just one.
                assocs_by_ledger_id = {}
                eo[:rows].each do |r|
                  arr = []
                  assocs_by_ledger_id[r.id] = arr
                  r.associations[:combined_book_transactions] = arr
                end
                ids = eo[:id_map].keys
                Suma::Payment::BookTransaction.
                  where(Sequel[originating_ledger_id: ids] | Sequel[receiving_ledger_id: ids]).
                  order(*combined_dataset_sorter(ids)).all do |bt|
                  [:originating_ledger_id, :receiving_ledger_id].each do |k|
                    arr = assocs_by_ledger_id[bt[k]]
                    arr << bt if arr
                  end
                end
                assocs_by_ledger_id.each_value(&:uniq!)
              end) do |_ds|
    # Custom block for when we aren't using eager loading
    Suma::Payment::BookTransaction.
      where(Sequel[originating_ledger_id: id] | Sequel[receiving_ledger_id: id]).
      order(*self.class.combined_dataset_sorter(id))
  end

  def balance
    credits = self.received_book_transactions.sum(Money.new(0), &:amount)
    debits = self.originated_book_transactions.sum(Money.new(0), &:amount)
    return credits - debits
  end

  # Return true if this ledger can be used to purchase the given service.
  # This is done by comparing the vendor service categories on each.
  # If any of the VSCs for the service appear in ledger's VSC graph
  # (all its VSCs and descendants), we say the ledger can be used
  # to pay for the service
  # (whether the ledger has balance is checked separately).
  #
  # For example, given the VSC tree:
  # food -> grocery -> organic
  #                 -> packaged
  #      -> restaurant
  #
  # If a ledger has "food" assigned to it,
  # the VSC graph includes all of the above nodes.
  # any vendor services with these categories (grocery, packaged, etc)
  # can be purchased by this ledger.
  #
  # If the ledger had 'organic' assigned,
  # only vendor services with 'organic' assigned could be used.
  #
  # Note that ledgers and services can have multiple service categories.
  #
  # @param has_vnd_svc_categories [Suma::Vendor::HasServiceCategories]
  # @param exclude [Enumerable<Suma::Vendor::ServiceCategory>]
  #   Any categories in exclude are removed from consideration on the receiving ledger.
  #   Ledgers look at 'child' categories when considering if they can be used to purchase,
  #   and these exclusions apply verbatim, they do NOT apply recursively.
  #   So if this ledger has category 'x', and category 'x' has a chain x->y->z,
  #   excluding 'y' would only exclude 'y' and NOT 'z'
  #   (so a product/service that has category 'z' can be still be purchased by this ledger).
  #   Using exclude is pretty rare; generally it's only useful to exclude the 'cash' or top-level ledgers
  #   to figure out how much will be contributed from other ledgers.
  def can_be_used_to_purchase?(has_vnd_svc_categories, exclude: [])
    match = self.category_used_to_purchase(has_vnd_svc_categories, exclude:)
    return !match.nil?
  end

  # See can_be_used_to_purchase?. Returns the first matching category
  # which qualifies this ledger to pay for the vendor service.
  # We may need to refine this search algorithm in the future
  # if we find it doesn't select the right category.
  def category_used_to_purchase(has_vnd_svc_categories, exclude: [])
    service_cat_ids = has_vnd_svc_categories.vendor_service_categories.map(&:id)
    exclude_ids = exclude.map(&:id)
    return self.vendor_service_categories.find do |c|
      chain_ids = c.tsort.map(&:id) - exclude_ids
      !(service_cat_ids & chain_ids).empty?
    end
  end

  def rel_admin_link = self.account.rel_admin_link

  def admin_label
    lbl = "#{self.account.display_name} - #{self.name}"
    lbl = "(#{self.id}) #{lbl}" unless self.account.platform_account?
    return lbl
  end

  def search_label
    return self.admin_label
  end
end

# Table: payment_ledgers
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                   | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at           | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at           | timestamp with time zone |
#  currency             | text                     | NOT NULL
#  name                 | text                     | NOT NULL
#  account_id           | integer                  |
#  contribution_text_id | integer                  | NOT NULL
# Indexes:
#  payment_ledgers_pkey                | PRIMARY KEY btree (id)
#  payment_ledgers_account_id_name_key | UNIQUE btree (account_id, name)
#  payment_ledgers_account_id_index    | btree (account_id)
# Foreign key constraints:
#  payment_ledgers_account_id_fkey           | (account_id) REFERENCES payment_accounts(id)
#  payment_ledgers_contribution_text_id_fkey | (contribution_text_id) REFERENCES translated_texts(id)
# Referenced By:
#  payment_book_transactions                 | payment_book_transactions_originating_ledger_id_fkey     | (originating_ledger_id) REFERENCES payment_ledgers(id)
#  payment_book_transactions                 | payment_book_transactions_receiving_ledger_id_fkey       | (receiving_ledger_id) REFERENCES payment_ledgers(id)
#  payment_funding_transactions              | payment_funding_transactions_platform_ledger_id_fkey     | (platform_ledger_id) REFERENCES payment_ledgers(id) ON DELETE RESTRICT
#  vendor_service_categories_payment_ledgers | vendor_service_categories_payment_ledgers_ledger_id_fkey | (ledger_id) REFERENCES payment_ledgers(id)
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
