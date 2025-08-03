# frozen_string_literal: true

require "suma/admin_linked"
require "suma/payment"

class Suma::Payment::Ledger < Suma::Postgres::Model(:payment_ledgers)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked

  plugin :hybrid_search
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
               right_key: :category_id,
               order: order_desc(:slug)
  one_to_many :originated_book_transactions,
              class: "Suma::Payment::BookTransaction",
              key: :originating_ledger_id,
              order: order_desc(:apply_at)
  one_to_many :received_book_transactions,
              class: "Suma::Payment::BookTransaction",
              key: :receiving_ledger_id,
              order: order_desc(:apply_at)
  one_to_many :combined_book_transactions,
              class: "Suma::Payment::BookTransaction",
              read_only: true,
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

  # These are used for #transactions? to avoid writing a custom eager loader.
  # If we need this sort of thing more in the future, we can refactor it as needed,
  # it's sort of hacky.
  # NOTE: The Sequel[true] is due to some internal bug in Sequel we haven't looked into.
  # But without it, the 'originated_book_transactions' and 'received_book_transactions' datasets
  # get messed up, probably due to an issue in the tactical eager loader,
  # and you'll see tests fail.
  one_to_one :one_originated_book_transaction, clone: :originated_book_transactions, limit: 1, conditions: Sequel[true]
  one_to_one :one_received_book_transaction, clone: :received_book_transactions, limit: 1, conditions: Sequel[true]

  # True if the ledger has any lines, false if not.
  def any_transactions? = !(self.one_originated_book_transaction || self.one_received_book_transaction).nil?

  [:originating, :receiving].each do |direction|
    assoc = :"#{direction}_stats"
    total_method = :"total_#{direction}"
    count_method = :"count_#{direction}"
    fk = :"#{direction}_ledger_id"
    many_to_one assoc,
                read_only: true,
                key: :id,
                class: "Suma::Payment::Ledger",
                dataset: proc {
                  ds = Suma::Payment::BookTransaction.
                    where(fk => id).
                    select { amount_cents.as(amount) }
                  db.from(ds).select { [sum(amount).as(total_method), count(1).as(count_method)] }.naked
                },
                eager_loader: (lambda do |eo|
                  eo[:rows].each { |p| p.associations[total_method] = nil }
                  ds = Suma::Payment::BookTransaction.
                    where(fk => eo[:id_map].keys).
                    select { [fk.as(ledger_id), amount_cents.as(amount)] }
                  db.from(ds).
                    select_group(:ledger_id).
                    select_append { [sum(amount).as(total_method), count(1).as(count_method)] }.
                    all do |t|
                    p = eo[:id_map][t.delete(:ledger_id)].first
                    p.associations[total_method] = t
                  end
                end)

    define_method(total_method) do
      Money.new((self.send(assoc) || {}).fetch(total_method, 0), self.currency)
    end

    define_method(count_method) do
      (self.send(assoc) || {}).fetch(count_method, 0)
    end
  end
  alias total_debits total_originating
  alias count_debits count_originating
  alias total_credits total_receiving
  alias count_credits count_receiving

  def balance = self.total_credits - self.total_debits

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
  # @param [Suma::Vendor::HasServiceCategories] has_vnd_svc_categories
  def can_be_used_to_purchase?(has_vnd_svc_categories)
    match = self.category_used_to_purchase(has_vnd_svc_categories)
    return !match.nil?
  end

  # See can_be_used_to_purchase?. Returns the first matching category
  # which qualifies this ledger to pay for the vendor service.
  # We may need to refind this search algorithm in the future
  # if we find it doesn't select the right category.
  # @param [Suma::Vendor::HasServiceCategories] has_vnd_svc_categories
  # @return [Suma::Vendor::ServiceCategory]
  def category_used_to_purchase(has_vnd_svc_categories)
    if has_vnd_svc_categories.vendor_service_categories.empty?
      msg = "#{has_vnd_svc_categories.class.name}[#{has_vnd_svc_categories.pk}] " \
            "has no categories so cannot be purchased by anything"
      raise Suma::InvalidPrecondition, msg
    end
    if self.vendor_service_categories.empty?
      msg = "#{self.class.name}[#{self.pk}, name=#{self.name}] has no categories so cannot be used to purchase anything"
      raise Suma::InvalidPrecondition, msg
    end
    service_cat_ids = has_vnd_svc_categories.vendor_service_categories.map(&:id)
    return self.vendor_service_categories.find do |c|
      chain_ids = c.tsort.map(&:id)
      service_cat_ids.intersect?(chain_ids)
    end
  end

  def rel_admin_link = "/payment-ledger/#{self.id}"

  def admin_label
    lbl = "#{self.account.display_name} - #{self.name}"
    lbl = "(#{self.id}) #{lbl}" unless self.account.platform_account?
    return lbl
  end

  def search_label
    return self.admin_label
  end

  def hybrid_search_fields
    return [
      :name,
      :contribution_text,
      ["Owner", self.account.display_name],
    ]
  end

  def hybrid_search_facts
    return [
      self.account.platform_account? && "I belong to the platform account",
      self.account.member && "I belong to a member",
      self.account.vendor && "I belong to a vendor",
    ]
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
#  account_id           | integer                  | NOT NULL
#  contribution_text_id | integer                  | NOT NULL
#  search_content       | text                     |
#  search_embedding     | vector(384)              |
#  search_hash          | text                     |
# Indexes:
#  payment_ledgers_pkey                          | PRIMARY KEY btree (id)
#  payment_ledgers_account_id_name_key           | UNIQUE btree (account_id, name)
#  payment_ledgers_account_id_index              | btree (account_id)
#  payment_ledgers_search_content_tsvector_index | gin (to_tsvector('english'::regconfig, search_content))
# Foreign key constraints:
#  payment_ledgers_account_id_fkey           | (account_id) REFERENCES payment_accounts(id)
#  payment_ledgers_contribution_text_id_fkey | (contribution_text_id) REFERENCES translated_texts(id)
# Referenced By:
#  payment_book_transactions                 | payment_book_transactions_originating_ledger_id_fkey     | (originating_ledger_id) REFERENCES payment_ledgers(id)
#  payment_book_transactions                 | payment_book_transactions_receiving_ledger_id_fkey       | (receiving_ledger_id) REFERENCES payment_ledgers(id)
#  payment_funding_transactions              | payment_funding_transactions_platform_ledger_id_fkey     | (platform_ledger_id) REFERENCES payment_ledgers(id) ON DELETE RESTRICT
#  payment_payout_transactions               | payment_payout_transactions_platform_ledger_id_fkey      | (platform_ledger_id) REFERENCES payment_ledgers(id) ON DELETE RESTRICT
#  payment_triggers                          | payment_triggers_originating_ledger_id_fkey              | (originating_ledger_id) REFERENCES payment_ledgers(id)
#  vendor_service_categories_payment_ledgers | vendor_service_categories_payment_ledgers_ledger_id_fkey | (ledger_id) REFERENCES payment_ledgers(id)
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
