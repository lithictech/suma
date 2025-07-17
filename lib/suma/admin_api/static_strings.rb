# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::StaticStrings < Suma::AdminAPI::V1
  class StaticStringEntity < Suma::AdminAPI::Entities::BaseEntity
    expose :id
    expose :namespace
    expose :key
    expose :deprecated
    expose :en, &self.delegate_to(:text, :en, safe_with_default: "")
    expose :es, &self.delegate_to(:text, :es, safe_with_default: "")
  end

  class StaticStringGroup < Suma::AdminAPI::Entities::BaseEntity
    expose :namespace
    expose :strings, with: StaticStringEntity
  end

  helpers do
    def writeable_row
      check_role_access!(admin_member, :write, :localization)
      row = Suma::I18n::StaticString.find!(namespace: params[:namespace], key: params[:key])
      return row
    end
  end

  resource :static_strings do
    get do
      check_role_access!(admin_member, :read, :localization)
      rows = Suma::I18n::StaticString.dataset.
        association_left_join(:text).
        all
      rows.sort_by! { |r| [r.namespace, r.key] }
      groups = rows.group_by(&:namespace)
      result = groups.map { |k, rows| {namespace: k, strings: rows} }
      present_collection result, with: StaticStringGroup
    end

    params do
      requires :namespace, type: String
      requires :key, type: String
    end
    post :create do
      check_role_access!(admin_member, :write, :localization)
      row = Suma::I18n::StaticString.find_or_create_or_find(namespace: params[:namespace], key: params[:key]) do |s|
        s.modified_at = Time.now
      end
      status 200
      present row, with: StaticStringEntity
    end

    params do
      requires :namespace, type: String
      requires :key, type: String
      optional :en, type: String
      optional :es, type: String
    end
    post :update do
      row = writeable_row
      text = {en: params[:en] || "", es: params[:es] || ""}
      row.db.transaction do
        if row.text.nil?
          row.update(text: Suma::TranslatedText.create(text))
        else
          row.text.update(text)
        end
      end
      status 200
      present row, with: StaticStringEntity
    end

    params do
      requires :namespace, type: String
      requires :key, type: String
    end
    post :deprecate do
      row = writeable_row
      row.update(deprecated: true)
      status 200
      present row, with: StaticStringEntity
    end

    params do
      requires :namespace, type: String
      requires :key, type: String
    end
    post :undeprecate do
      row = writeable_row
      row.update(deprecated: false)
      status 200
      present row, with: StaticStringEntity
    end
  end
end
