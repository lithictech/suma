# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceOfferings < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class ListCommerceOfferingEntity < OfferingEntity
    expose :product_count
    expose :order_count
  end

  class OrderInOfferingEntity < OrderEntity
    expose :total_item_count
  end

  class DetailedOfferingEntity < OfferingEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :description, with: TranslatedTextEntity
    expose :fulfillment_prompt, with: TranslatedTextEntity
    expose :fulfillment_instructions, with: TranslatedTextEntity
    expose :fulfillment_confirmation, with: TranslatedTextEntity
    expose :fulfillment_options, with: OfferingFulfillmentOptionEntity
    expose :begin_fulfillment_at
    expose :image, with: ImageEntity, &self.delegate_to(:images?, :first)
    expose :offering_products, with: OfferingProductEntity
    expose :orders, with: OrderInOfferingEntity
    expose :eligibility_constraints, with: EligibilityConstraintEntity
    expose :max_ordered_items_cumulative
    expose :max_ordered_items_per_member
  end

  class PicklistSimpleMemberEntity < MemberEntity
    expose :phone_last4
  end

  class PicklistProductEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose_translated :name
  end

  class PicklistOfferingProductEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :product, with: PicklistProductEntity
  end

  class PicklistFulfillmentOptionEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose_translated :description
  end

  class PicklistOrderItemEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :id
    expose :quantity
    expose :serial
    expose :member, with: PicklistSimpleMemberEntity
    expose :offering_product, with: PicklistOfferingProductEntity
    expose :fulfillment_option, with: PicklistFulfillmentOptionEntity
    expose :status
  end

  class PicklistEntity < BaseEntity
    expose :order_items, with: PicklistOrderItemEntity
  end

  resource :commerce_offerings do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Commerce::Offering,
      ListCommerceOfferingEntity,
      translation_search_params: [:description],
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Commerce::Offering,
      DetailedOfferingEntity,
    ) do
      params do
        requires :image, type: File
        requires(:description, type: JSON) { use :translated_text }
        optional(:fulfillment_prompt, type: JSON) { use :translated_text, allow_blank: true  }
        optional(:fulfillment_instructions, type: JSON) { use :translated_text, allow_blank: true  }
        optional(:fulfillment_confirmation, type: JSON) { use :translated_text, allow_blank: true  }
        optional :fulfillment_options,
                 type: Array,
                 coerce_with: proc { |s| s.values.each_with_index.map { |fo, ordinal| fo.merge(ordinal:) } } do
          requires :type, type: String, values: Suma::Commerce::OfferingFulfillmentOption::TYPES
          requires(:description, type: JSON) { use :translated_text }
          optional(:address, type: JSON) { use :address }
          optional :ordinal, type: Integer
        end
        requires :period_begin, type: Time
        requires :period_end, type: Time
        optional :begin_fulfillment_at, type: Time
        optional :max_ordered_items_cumulative, type: Integer
        optional :max_ordered_items_per_member, type: Integer
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Commerce::Offering, DetailedOfferingEntity)

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Commerce::Offering,
      DetailedOfferingEntity,
    ) do
      params do
        optional :image, type: File
        optional(:description, type: JSON) { use :translated_text }
        optional(:fulfillment_prompt, type: JSON) { use :translated_text, allow_blank: true }
        optional(:fulfillment_instructions, type: JSON) { use :translated_text, allow_blank: true }
        optional(:fulfillment_confirmation, type: JSON) { use :translated_text, allow_blank: true }
        optional :fulfillment_options,
                 type: Array,
                 coerce_with: proc { |s| s.values.each_with_index.map { |fo, ordinal| fo.merge(ordinal:) } } do
          optional :id, type: Integer
          requires :type, type: String, values: Suma::Commerce::OfferingFulfillmentOption::TYPES
          requires(:description, type: JSON) { use :translated_text }
          optional(:address, default: nil, type: JSON) { use :address }
          optional :ordinal, type: Integer
        end
        optional :period_begin, type: Time
        optional :period_end, type: Time
        optional :begin_fulfillment_at, type: Time
        optional :max_ordered_items_cumulative, type: Integer
        optional :max_ordered_items_per_member, type: Integer
      end
    end

    route_param :id, type: Integer do
      helpers do
        def lookup
          (co = Suma::Commerce::Offering[params[:id]]) or forbidden!
          return co
        end
      end

      params do
        requires :constraint_ids, type: Array[Integer], coerce_with: CommaSepArray[Integer]
      end
      post :eligibilities do
        offering = lookup
        params[:constraint_ids].each do |id|
          Suma::Eligibility::Constraint[id] or adminerror!(403, "Unknown eligibility constraint: #{id}")
        end
        offering.replace_eligibility_constraints(params[:constraint_ids])
        summary = offering.eligibility_constraints_dataset.select_map(:name).join(", ")
        admin_member.add_activity(
          message_name: "eligibilitychange",
          summary: "Admin #{admin_member.email} modified eligibilities of #{offering.description.en}: #{summary}",
          subject_type: offering.model,
          subject_id: offering.id,
        )

        status 200
        present offering, with: DetailedOfferingEntity
      end

      resource :picklist do
        get do
          offering = lookup
          picklist = Suma::Commerce::OfferingPicklist.new(offering).build
          present picklist, with: PicklistEntity
        end
      end
    end
  end
end
