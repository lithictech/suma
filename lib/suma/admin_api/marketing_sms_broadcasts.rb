# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::MarketingSmsBroadcasts < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class DetailedSmsBroadcastEntity < MarketingSmsBroadcastEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :created_by, with: MemberEntity
    expose :body, with: TranslatedTextEntity
    expose :sending_number
    expose :sending_number_formatted
    expose :lists, with: MarketingListEntity
    expose :all_lists, with: MarketingListEntity do |_inst|
      Suma::Marketing::List.dataset.order(:label).all
    end
    expose :preview do |instance, opts|
      instance.preview(opts.fetch(:env).fetch("yosoy").authenticated_object!.member)
    end
    expose :sms_dispatches, with: MarketingSmsDispatchEntity
    expose :available_sending_numbers do |_instance|
      Suma::Marketing::SmsBroadcast.available_sending_numbers
    end
  end

  class SmsBroadcastPayloadEntity < BaseEntity
    expose :characters
    expose :segments
    expose :cost
  end

  class SmsBroadcastPreReviewEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :broadcast, with: MarketingSmsBroadcastEntity
    expose :list_labels
    expose :total_recipients
    expose :en_recipients
    expose :es_recipients
    expose :total_cost
    expose :en_total_cost
    expose :es_total_cost
    expose :pre_review?, as: :pre_review
  end

  class SmsBroadcastPostReviewEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :broadcast, with: MarketingSmsBroadcastEntity
    expose :list_labels
    expose :total_recipients
    expose :delivered_recipients
    expose :failed_recipients
    expose :canceled_recipients
    expose :pending_recipients
    expose :actual_cost
    expose :pre_review?, as: :pre_review
  end

  resource :marketing_sms_broadcasts do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Marketing::SmsBroadcast,
      MarketingSmsBroadcastEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Marketing::SmsBroadcast,
      DetailedSmsBroadcastEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Marketing::SmsBroadcast,
      DetailedSmsBroadcastEntity,
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
      check_admin_role_access!(:read, Suma::Marketing::SmsBroadcast)
      preview = Suma::Marketing::SmsBroadcast.preview(member: admin_member, en: params[:en], es: params[:es])
      status 200
      present preview
    end

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Marketing::SmsBroadcast,
      DetailedSmsBroadcastEntity,
      around: lambda do |rt, m, &block|
        lists = rt.params.delete(:lists)
        block.call
        m.list_pks = lists.map { |l| l.fetch(:id) } if
          lists
      end,
    ) do
      params do
        optional :label, type: String
        optional :sending_number, type: String
        optional(:body, type: JSON) { use :translated_text, allow_blank: true }
        optional :lists, type: Array
      end
    end

    route_param :id, type: Integer do
      get :review do
        check_admin_role_access!(:read, Suma::Marketing::SmsBroadcast)
        (o = Suma::Marketing::SmsBroadcast[params[:id]]) or forbidden!
        r = o.generate_review
        entity = r.pre_review? ? SmsBroadcastPreReviewEntity : SmsBroadcastPostReviewEntity
        status 200
        present r, with: entity
      end

      post :send do
        check_admin_role_access!(:write, Suma::Marketing::SmsBroadcast)
        (o = Suma::Marketing::SmsBroadcast[params[:id]]) or forbidden!
        o.dispatch
        created_resource_headers(o.id, o.admin_link)
        status 200
        present o, with: DetailedSmsBroadcastEntity
      end
    end
  end
end
