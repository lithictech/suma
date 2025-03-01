# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Search < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :search do
    helpers do
      def ds_search_or_order_by(column_sym, ds, params)
        if (namelike = search_param_to_sql(params, column_sym, param: :q))
          return ds.where(namelike)
        end
        return ds.order(column_sym)
      end
    end
    resource :ledgers do
      params do
        optional :q, type: String
      end
      post do
        check_role_access!(admin_member, :read, :admin_payments)
        ds = Suma::Payment::Ledger.dataset
        if (q = params[:q]).present?
          # Search for ledgers, members, and vendors containing the given name.
          search_cond = search_to_sql(q, :name) |
            Sequel[account: Suma::Payment::Account.where(
              Sequel[member: Suma::Member.where(search_to_sql(q, :name))] |
                Sequel[vendor: Suma::Vendor.where(search_to_sql(q, :name))],
            )]
          # Handle the keywords 'suma' and 'platform' specially.
          # If they are present, include in the search results platform accounts that
          # match the remaining search terms. For example, 'suma food' would return all platform ledgers
          # that have the name 'food'.
          # It would also return all non-platform ledgers that have the string 'suma food' in them.
          # This allows the common use case of something like 'suma cash' for the platform cash ledger.
          name_words = q.downcase.split
          if name_words.include?("suma") || name_words.include?("platform")
            platform_search_words = name_words.dup
            platform_search_words.delete("suma")
            platform_search_words.delete("platform")
            platform_name_cond = search_to_sql(platform_search_words.join(" "), :name)
            platform_acct_cond = Sequel[account: Suma::Payment::Account.where(is_platform_account: true)]
            pcond = platform_search_words.empty? ? platform_acct_cond : (platform_name_cond & platform_acct_cond)
            search_cond |= pcond
          end
          ds = ds.where(search_cond)
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
        check_role_access!(admin_member, :read, :admin_payments)
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
      check_role_access!(admin_member, :read, :admin_members)
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
      check_role_access!(admin_member, :read, :admin_access)
      lang = params[:language]
      # Perform a subselect since otherwise we can't sort with distinct.
      base_ds = Suma::TranslatedText.dataset.distinct(lang)
      if (types = params[:types])
        base_ds = nil if types.include?(:ignore_this_i_just_dont_want_reformatting)
        base_ds = base_ds.where(id: Suma::Payment::BookTransaction.dataset.select(:memo_id)) if types.include?(:memo)
      end
      ds = Suma::TranslatedText.dataset.where(id: base_ds.select(:id)).search(lang, params[:q])
      ds = ds.limit(10)
      status 200
      present_collection ds, with: SearchTransactionEntity, language: lang
    end

    params do
      optional :q, type: String
    end
    post :products do
      check_role_access!(admin_member, :read, :admin_commerce)
      ds = Suma::Commerce::Product.dataset
      if (q = params[:q]).present?
        name_like = Suma::TranslatedText.dataset.distinct_search(:en, q)
        ds = ds.where(name: name_like)
      end
      ds = ds.limit(15)
      status 200
      present_collection ds, with: SearchProductEntity
    end

    params do
      optional :q, type: String
    end
    post :offerings do
      check_role_access!(admin_member, :read, :admin_commerce)
      ds = Suma::Commerce::Offering.dataset
      if (q = params[:q]).present?
        description_like = Suma::TranslatedText.dataset.distinct_search(:en, q)
        ds = ds.where(description: description_like)
      end
      ds = ds.limit(15)
      status 200
      present_collection ds, with: SearchOfferingEntity
    end

    params do
      optional :q, type: String
    end
    post :vendors do
      check_role_access!(admin_member, :read, :admin_commerce)
      ds = Suma::Vendor.dataset
      ds = ds_search_or_order_by(:name, ds, params)
      ds = ds.limit(15)
      status 200
      present_collection ds, with: SearchVendorEntity
    end

    params do
      optional :q, type: String
    end
    post :members do
      check_role_access!(admin_member, :read, :admin_members)
      ds = Suma::Member.dataset.not_soft_deleted
      ds = ds_search_or_order_by(:name, ds, params)
      ds = ds.limit(15)
      status 200
      present_collection ds, with: SearchMemberEntity
    end

    params do
      optional :q, type: String
    end
    post :organizations do
      check_role_access!(admin_member, :read, :admin_members)
      ds = Suma::Organization.dataset
      ds = ds_search_or_order_by(:name, ds, params)
      ds = ds.limit(15)
      status 200
      present_collection ds, with: SearchOrganizationEntity
    end

    params do
      optional :q, type: String
    end
    post :roles do
      check_role_access!(admin_member, :read, :admin_members)
      # role names are sluggified by default.
      params[:q] = Suma.to_slug(params[:q]) if params[:q].present?
      ds = Suma::Role.dataset
      ds = ds_search_or_order_by(:name, ds, params)
      ds = ds.limit(15)
      status 200
      present_collection ds, with: SearchRoleEntity
    end

    params do
      optional :q, type: String
    end
    post :vendor_services do
      check_role_access!(admin_member, :read, :admin_commerce)
      ds = Suma::Vendor::Service.dataset
      ds = ds_search_or_order_by(:external_name, ds, params)
      ds = ds.limit(15)
      status 200
      present_collection ds, with: SearchVendorServiceEntity
    end

    params do
      optional :q, type: String
    end
    post :commerce_offerings do
      check_role_access!(admin_member, :read, :admin_commerce)
      ds = Suma::Commerce::Offering.dataset
      if (description_en_like = search_param_to_sql(params, :description_en, param: :q))
        description_es_like = search_param_to_sql(params, :description_es, param: :q)
        ds = ds.translation_join(:description, [:en, :es])
        ds = ds.reduce_expr(:|, [description_en_like, description_es_like])
      end
      ds = ds.order(Sequel.desc(:id), Sequel.desc(:id))
      ds = ds.limit(15)
      status 200
      present_collection ds, with: SearchCommerceOfferingEntity
    end

    params do
      optional :q, type: String
    end
    post :programs do
      check_role_access!(admin_member, :read, :admin_management)
      ds = Suma::Program.dataset
      if (name_en_like = search_param_to_sql(params, :name_en, param: :q))
        name_es_like = search_param_to_sql(params, :name_es, param: :q)
        ds = ds.translation_join(:name, [:en, :es])
        ds = ds.reduce_expr(:|, [name_en_like, name_es_like])
      end
      ds = ds.order(Sequel.desc(:id), Sequel.desc(:id))
      ds = ds.limit(15)
      status 200
      present_collection ds, with: SearchProgramEntity
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

  class SearchProductEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :id
    expose :admin_link
    expose :label, &self.delegate_to(:name, :en)
  end

  class SearchOfferingEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :id
    expose :admin_link
    expose :label, &self.delegate_to(:description, :en)
  end

  class SearchVendorEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :id
    expose :slug
    expose :admin_link
    expose :name, as: :label
  end

  class SearchMemberEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :id
    expose :admin_link
    expose :name
    expose :search_label, as: :label
  end

  class SearchOrganizationEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :id
    expose :admin_link
    expose :name
    expose :name, as: :label
  end

  class SearchRoleEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :id
    expose :admin_link
    expose :name
    expose :label
  end

  class SearchVendorServiceEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :id
    expose :admin_link
    expose :external_name, as: :name
    expose :external_name, as: :label
  end

  class SearchCommerceOfferingEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :id
    expose :admin_link
    expose :name, &self.delegate_to(:description, :en)
    expose :label, &self.delegate_to(:description, :en)
  end

  class SearchProgramEntity < BaseEntity
    expose :key, &self.delegate_to(:id, :to_s)
    expose :id
    expose :admin_link
    expose :name, &self.delegate_to(:name, :en)
    expose :label, &self.delegate_to(:name, :en)
  end
end
