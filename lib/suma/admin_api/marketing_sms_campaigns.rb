# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::MarketingSmsCampaigns < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedSmsCampaignEntity < SmsCampaignEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :created_by, with: MemberEntity
    expose :body, with: TranslatedTextEntity
  end

  resource :marketing_sms_campaigns do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Marketing::SmsCampaign,
      SmsCampaignEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Marketing::SmsCampaign,
      DetailedSmsCampaignEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Marketing::SmsCampaign,
      DetailedSmsCampaignEntity,
    ) do
      params do
        requires :label, type: String
      end
    end

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Marketing::SmsCampaign,
      DetailedSmsCampaignEntity,
      around: lambda do |rt, m, &block|
        lists = rt.params.delete(:lists)
        block.call
        m.list_pks = lists.map { |l| l.fetch(:id) } if
          lists
      end,
    ) do
      params do
        optional :label, type: String
        optional(:body, type: JSON) { use :translated_text, allow_blank: true }
        optional :lists, type: Array
      end
    end
  end
end
