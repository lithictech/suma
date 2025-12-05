# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::MarketingLists < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedListEntity < MarketingListEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :members, with: MarketingMemberEntity
    expose :sms_broadcasts, with: MarketingSmsBroadcastEntity
  end

  resource :marketing_lists do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Marketing::List,
      MarketingListEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Marketing::List,
      DetailedListEntity,
    ) do
      params do
        requires :label, type: String
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Marketing::List,
      DetailedListEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Marketing::List,
      DetailedListEntity,
      around: lambda do |rt, m, &block|
        rt.adminerror!(403, "Managed lists cannot be edited", code: "marketing_list_managed") if m.managed?
        members = rt.params.delete(:members)
        block.call
        m.member_pks = members.map { |l| l.fetch(:id) } if
          members
      end,
    ) do
      params do
        optional :label, type: String
        optional :members, type: Array
      end
    end

    Suma::AdminAPI::CommonEndpoints.destroy(
      self,
      Suma::Marketing::List,
      DetailedListEntity,
    )

    route_param :id, type: Integer do
      helpers do
        def lookup
          Suma::Marketing::List[params[:id]]
        end or forbidden!
      end

      post :rebuild do
        check_admin_role_access!(:read, :marketing_sms)
        list = lookup
        sleep(1)
        adminerror!(403, "Only managed lists can be rebuilt", code: "marketing_list_unmanaged") unless list.managed
        spec = Suma::Marketing::List::Specification.gather_all.find { |spec| spec.full_label == list.label }
        if spec.nil?
          msg = "Could not find a list specification- this list should be unmanaged, please alert a developer"
          adminerror!(403, msg, code: "marketing_list_spec_missing")
        end
        Suma::Marketing::List.rebuild(spec)
        list.refresh
        status 200
        present list, with: DetailedListEntity
      end
    end
  end
end
