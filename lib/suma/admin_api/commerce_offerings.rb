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

  class DetailedCommerceOfferingEntity < OfferingEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose_translated :description
    expose_translated :fulfillment_prompt
    expose_translated :fulfillment_confirmation
    expose :fulfillment_options, with: OfferingFulfillmentOptionEntity
    expose :begin_fulfillment_at
    expose :prohibit_charge_at_checkout
    expose :image, with: ImageEntity, &self.delegate_to(:images?, :first)
    expose :offering_products, with: OfferingProductEntity
    expose :orders, with: OrderInOfferingEntity
    expose :eligibility_constraints, with: EligibilityConstraintEntity
  end

  class ProductInPickListEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose_translated :name
  end

  class OrderItemsPickListEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :id
    expose :quantity
    expose :serial, &self.delegate_to(:checkout, :order, :serial)
    expose :member, with: MemberEntity, &self.delegate_to(:checkout, :cart, :member)
    expose :product, with: ProductInPickListEntity, &self.delegate_to(:offering_product, :product)
    expose_translated :fulfillment, &self.delegate_to(:checkout, :fulfillment_option, :description)
  end

  resource :commerce_offerings do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Commerce::Offering,
      ListCommerceOfferingEntity,
      translation_search_params: [:description],
    )

    params do
      requires :image, type: File
      requires :description, type: JSON do
        use :translated_text
      end
      requires :fulfillment_prompt, type: JSON do
        use :translated_text
      end
      requires :fulfillment_confirmation, type: JSON do
        use :translated_text
      end
      requires :fulfillment_options,
               type: Array,
               coerce_with: proc { |s| s.values.each_with_index.map { |fo, ordinal| fo.merge(ordinal:) } } do
        requires :type, type: String, values: Suma::Commerce::OfferingFulfillmentOption::TYPES
        requires :description, type: JSON
        optional :address, type: JSON do
          use :address
        end
      end
      requires :opens_at, type: Time
      requires :closes_at, type: Time
      optional :begin_fulfillment_at, type: Time, allow_blank: true
      optional :prohibit_charge_at_checkout, type: Boolean, allow_blank: true
    end
    post :create do
      Suma::Commerce::Offering.db.transaction do
        offering = Suma::Commerce::Offering.create(
          description: Suma::TranslatedText.find_or_create(**params[:description]),
          fulfillment_prompt: Suma::TranslatedText.find_or_create(**params[:fulfillment_prompt]),
          fulfillment_confirmation: Suma::TranslatedText.find_or_create(**params[:fulfillment_confirmation]),
          period: params[:opens_at]..params[:closes_at],
          begin_fulfillment_at: params[:begin_fulfillment_at],
          prohibit_charge_at_checkout: params[:prohibit_charge_at_checkout] || false,
        )

        params[:fulfillment_options]&.each do |fo|
          fo_params = {
            description: Suma::TranslatedText.find_or_create(**fo[:description]),
            type: fo[:type],
            ordinal: fo[:ordinal],
          }
          if (addr_params = fo[:address])
            fo_params[:address] = Suma::Address.lookup(addr_params)
          end
          offering.add_fulfillment_option(fo_params)
        end

        if (image_params = params[:image])
          uf = Suma::UploadedFile.create_from_multipart(image_params)
          offering.add_image({uploaded_file: uf})
        end

        created_resource_headers(offering.id, offering.admin_link)
        status 200
        present offering, with: DetailedCommerceOfferingEntity
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Commerce::Offering, DetailedCommerceOfferingEntity)

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
        admin = admin_member
        offering.db.transaction do
          to_remove = offering.eligibility_constraints_dataset.exclude(id: params[:constraint_ids])
          to_add = []
          params[:constraint_ids].each do |id|
            Suma::Eligibility::Constraint[id] or adminerror!(403, "Unknown eligibility constraint: #{id}")
            to_add << id
          end
          to_add = Suma::Eligibility::Constraint.where(id: to_add).
            exclude(id: offering.eligibility_constraints_dataset.select(:id))
          to_add.each do |c|
            offering.add_eligibility_constraint(c)
          end
          to_remove.each do |c|
            offering.remove_eligibility_constraint(c)
          end

          summary = offering.eligibility_constraints_dataset.select_map(:name).join(", ")
          admin_member.add_activity(
            message_name: "eligibilitychange",
            summary: "Admin #{admin.email} modified eligibilities of #{offering.description.en}: #{summary}",
            subject_type: "Suma::Commerce::Offering",
            subject_id: offering.id,
          )
        end
        status 200
        present offering, with: DetailedCommerceOfferingEntity
      end

      resource :picklist do
        get do
          co_products = lookup.order_pick_list
          present_collection co_products, with: OrderItemsPickListEntity
        end
      end
    end
  end
end
