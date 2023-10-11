# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceOfferings < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :commerce_offerings do
    params do
      use :pagination
      use :ordering, model: Suma::Commerce::Offering
      use :searchable
    end
    get do
      ds = Suma::Commerce::Offering.dataset
      if (descriptionen_like = search_param_to_sql(params, :description_en))
        descriptiones_like = search_param_to_sql(params, :description_es)
        ds = ds.translation_join(:description, [:en, :es]).where(descriptionen_like | descriptiones_like)
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: ListCommerceOfferingEntity
    end

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

    route_param :id, type: Integer do
      helpers do
        def lookup
          (co = Suma::Commerce::Offering[params[:id]]) or forbidden!
          return co
        end
      end

      get do
        co = lookup
        present co, with: DetailedCommerceOfferingEntity
      end

      resource :picklist do
        get do
          co_products = lookup.order_pick_list
          present_collection co_products, with: OrderItemsPickListEntity
        end
      end
    end
  end

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
end
