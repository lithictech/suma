# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::MarketingSmsCampaigns < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedSmsCampaignEntity < MarketingSmsCampaignEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :created_by, with: MemberEntity
    expose :body, with: TranslatedTextEntity
    expose :lists, with: MarketingListEntity
    expose :all_lists, with: MarketingListEntity do |_inst|
      Suma::Marketing::List.dataset.order(:label).all
    end
    expose :preview do |instance, opts|
      instance.preview(opts.fetch(:env).fetch("yosoy").authenticated_object!.member)
    end
    expose :sms_dispatches, with: MarketingSmsDispatchEntity
  end

  class SmsCampaignPayloadEntity < BaseEntity
    expose :characters
    expose :segments
    expose :cost
  end

  class SmsCampaignReviewEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :campaign, with: MarketingSmsCampaignEntity
    expose :list_labels
    expose :total_recipient_count
    expose :en_recipient_count
    expose :es_recipient_count
    expose :total_cost
    expose :en_total_cost
    expose :es_total_cost
  end

  resource :marketing_sms_campaigns do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Marketing::SmsCampaign,
      MarketingSmsCampaignEntity,
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

    params do
      requires :en, type: String
      requires :es, type: String
    end
    post :preview do
      preview = Suma::Marketing::SmsCampaign.preview(member: admin_member, en: params[:en], es: params[:es])
      status 200
      present preview
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

    route_param :id, type: Integer do
      get :review do
        (o = Suma::Marketing::SmsCampaign[params[:id]]) or forbidden!
        r = o.generate_review
        status 200
        present r, with: SmsCampaignReviewEntity
      end

      post :send do
        (o = Suma::Marketing::SmsCampaign[params[:id]]) or forbidden!
        o.dispatch
        created_resource_headers(o.id, o.admin_link)
        status 200
        present o, with: DetailedSmsCampaignEntity
      end
    end
  end
end
