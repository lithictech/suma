# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::SmsMarketing < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class MarketingList < BaseEntity
  end

  resource :sms_marketing do
    desc "Return the lists that can be used for bulk distribution."
    get :lists do
      check_role_access!(admin_member, :read, :marketing_sms)
      lists = Suma::Marketing::List.all_lists
      present_collection lists, with: MarketingList
    end

    params do
      requires :body, type: String, allow_blank: true
    end
    get :preview do
      check_role_access!(admin_member, :read, :marketing_sms)
      rendered_result = Suma::Marketing.preview(params[:body], member: admin_member)
      empty_result = Suma::Marketing.preview(params[:body], member: Suma::Member.new)
      result = {
        member: rendered_result,
        empty: empty_result,
      }
      present result
    end

    desc "Send a message to the given lists."
    params do
      requires :list_keys, Array[String]
      requires :body, type: String, allow_blank: false
    end
    post :send_sms do
      check_role_access!(admin_member, :write, :marketing_sms)
      lists = Suma::Marketing::List.all_lists.select { |li| params[:list_keys].include?(li.key) }
      Suma::Marketing::Sms.dispatch(lists:, body: params[:body])
    end
  end
end
