# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Search < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :search do
    resource :ledgers do
      params do
        optional :q, type: String
      end
      post do
        ds = Suma::Payment::Ledger.dataset
        if (q = params[:q]).present?
          conds = search_to_sql(q, :name) |
            Sequel[account: Suma::Payment::Account.where(
              Sequel[member: Suma::Member.where(search_to_sql(q, :name))] |
                Sequel[vendor: Suma::Vendor.where(search_to_sql(q, :name))],
            )]
          ds = ds.where(conds)
        end
        ds = ds.order(:name).limit(15)
        status 200
        present_collection ds, with: SearchLedgerEntity
      end

      params do
        optional :ids, type: Array[Integer]
        optional :platform_categories, type: Array[String]
      end
      post :lookup do
        by_id = {}
        params.fetch(:ids, []).each do |ledger_id|
          led = Suma::Payment::Ledger[ledger_id]
          by_id[led.id.to_s] = led if led
        end
        platform_by_category = {}
        platform = Suma::Payment::Account.lookup_platform_account
        params.fetch(:platform_categories, []).each do |slug|
          led = platform.ledgers_dataset[vendor_service_categories: Suma::Vendor::ServiceCategory.where(slug:)]
          platform_by_category[slug] = led if led
        end
        result = {
          by_id: by_id.transform_values { |v| SearchLedgerEntity.represent(v) },
          platform_by_category: platform_by_category.transform_values { |v| SearchLedgerEntity.represent(v) },
        }
        status 200
        present result
      end
    end

    params do
      optional :q, type: String
      optional :types, type: Array[Symbol], values: [:bank_account, :card]
    end
    post :payment_instruments do
      ba_ds = Suma::Payment::BankAccount.dataset.usable.verified
      card_ds = Suma::Payment::Card.dataset.usable
      if (types = params[:types]).present?
        ba_ds = ba_ds.where(1 => 2) unless types.include?(:bank_account)
        card_ds = card_ds.where(1 => 2) unless types.include?(:card)
      end
      if (q = params[:q]).present?
        legal_entity_search = Sequel[legal_entity: Suma::LegalEntity.where(
          search_to_sql(q, :name) |
            Sequel[member: Suma::Member.where(search_to_sql(q, :name))],
        )]
        ba_ds = ba_ds.where(search_to_sql(q, :name) | legal_entity_search)
        card_ds = card_ds.where(
          search_to_sql(q, Sequel.pg_json_op(:stripe_json).get_text("last4")) |
            legal_entity_search,
        )
      end
      unioned_ds = ba_ds.select(
        :id,
        Sequel.as("bank_account", :payment_method_type),
        :legal_entity_id,
        :name,
        :account_number,
        :plaid_institution_id,
        Sequel.as("{}", :stripe_json),
        Sequel.as(:name, :ordering),
      ).union(
        card_ds.select(
          :id,
          Sequel.as("card", :payment_method_type),
          :legal_entity_id,
          Sequel.as("", :name),
          Sequel.as("", :account_number),
          Sequel.as(0, :plaid_institution_id),
          :stripe_json,
          Sequel.pg_json_op(:stripe_json).get_text("last4").as(:ordering),
        ),
      )
      unioned_ds = unioned_ds.order(:ordering).limit(15)
      instruments = unioned_ds.naked.map do |row|
        model = row[:payment_method_type] == "card" ? Suma::Payment::Card : Suma::Payment::BankAccount
        id = row.delete(:id)
        # Disable strict mode so we ignore the common rows in the union
        m = model.with_setting(:strict_param_setting, false) do
          model.new(**row)
        end
        m.id = id
        m
      end
      status 200
      present_collection instruments, with: SearchPaymentInstrumentEntity
    end

    params do
      requires :q, type: String, allow_blank: false
      optional :types, type: Array[Symbol], values: [:memo]
      optional :language, type: Symbol, values: [:en, :es], default: :en
    end
    post :translations do
      lang = params[:language]
      pglang = {en: "english", es: "spanish"}.fetch(lang)
      # Perform a subselect since otherwise we can't sort with distinct.
      base_ds = Suma::TranslatedText.dataset.distinct(lang)
      if (types = params[:types])
        base_ds = nil if types.include?(:ignore_this_i_just_dont_want_reformatting)
        base_ds = base_ds.where(id: Suma::Payment::BookTransaction.dataset.select(:memo_id)) if types.include?(:memo)
      end
      ds = Suma::TranslatedText.dataset.where(id: base_ds.select(:id)).full_text_search(
        # Search using the generated column
        "#{lang}_tsvector".to_sym,
        # Have to do this manually for now: https://github.com/jeremyevans/sequel/discussions/2075
        Sequel.function(:websearch_to_tsquery, pglang, params[:q]),
        rank: true,
        language: pglang,
        tsvector: true,
        tsquery: true,
      )
      ds = ds.limit(10)
      status 200
      present_collection ds, with: SearchTransactionEntity, language: lang
    end
  end

  class SearchLedgerEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :id
    expose :admin_link
    expose :search_label, as: :label
  end

  class SearchPaymentInstrumentEntity < BaseEntity
    expose :key do |inst|
      "#{inst.id}-#{inst.payment_method_type}"
    end
    expose :id
    expose :payment_method_type
    expose :admin_link
    expose :search_label, as: :label
  end

  class SearchTransactionEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :en
    expose :es
    expose :label do |inst, options|
      inst.send(options[:language])
    end
  end
end
