# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::StaticStrings < Suma::AdminAPI::V1
  class BaseStaticStringEntity < Suma::AdminAPI::Entities::BaseEntity
    expose :id
    expose :namespace
    expose :key
    expose :deprecated
    expose :needs_text?, as: :needs_text
  end

  class JoinedStaticStringEntity < BaseStaticStringEntity
    expose(:en) { |inst| inst.values[:en] || "" }
    expose(:es) { |inst| inst.values[:es] || "" }
  end

  class StandaloneStaticStringEntity < BaseStaticStringEntity
    expose :en, &self.delegate_to(:text, :en, safe_with_default: "")
    expose :es, &self.delegate_to(:text, :es, safe_with_default: "")
  end

  class StaticStringGroup < Suma::AdminAPI::Entities::BaseEntity
    expose :namespace
    expose :strings, with: JoinedStaticStringEntity
  end

  resource :static_strings do
    helpers do
      def notify_change = Suma::I18n::StaticStringRebuilder.notify_change
    end

    get do
      check_admin_role_access!(:read, Suma::I18n::StaticString)
      rows = Suma::I18n::StaticString.dataset.
        select_all(:i18n_static_strings).
        association_left_join(:text).
        select_append(:en).
        select_append(:es).
        all
      rows.sort_by! { |r| [r.deprecated ? 1 : 0, r.namespace, r.key] }
      groups = rows.group_by(&:namespace)
      result = groups.map { |k, rows| {namespace: k, strings: rows} }
      present_collection result, with: StaticStringGroup
    end

    params do
      requires :namespace, type: String
      requires :key, type: String
    end
    post :create do
      check_admin_role_access!(:write, Suma::I18n::StaticString)
      row = Suma::I18n::StaticString.find_or_create_or_find(namespace: params[:namespace], key: params[:key]) do |s|
        s.modified_at = Time.now
      end
      created_resource_headers(row.id, "/static-strings-namespace/#{row.namespace}")
      notify_change
      status 200
      present row, with: StandaloneStaticStringEntity
    end

    route_param :id, type: Integer do
      helpers do
        def writeable_row
          check_admin_role_access!(:write, Suma::I18n::StaticString)
          row = Suma::I18n::StaticString.find!(id: params[:id])
          return row
        end
      end

      params do
        Suma::I18n::SUPPORTED_LOCALES.each_key do |lc|
          optional lc.to_sym, type: String
        end
      end
      post :update do
        row = writeable_row
        text = {}
        Suma::I18n::SUPPORTED_LOCALES.each_key do |lc|
          lc = lc.to_sym
          text[lc] = params[lc] if params.key?(lc)
        end
        row.db.transaction do
          if row.text.nil?
            row.update(text: Suma::TranslatedText.create(text), modified_at: Time.now)
          else
            row.text.update(text)
            row.update(modified_at: Time.now)
          end
        end
        notify_change
        status 200
        present row, with: StandaloneStaticStringEntity
      end

      post :deprecate do
        row = writeable_row
        row.update(deprecated: true, modified_at: Time.now)
        notify_change
        status 200
        present row, with: StandaloneStaticStringEntity
      end

      post :undeprecate do
        row = writeable_row
        row.update(deprecated: false, modified_at: Time.now)
        notify_change
        status 200
        present row, with: StandaloneStaticStringEntity
      end
    end
  end
end
