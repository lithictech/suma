# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Customers < Suma::AdminAPI::V1
  ALL_TIMEZONES = Set.new(TZInfo::Timezone.all_identifiers)

  resource :customers do
    desc "Return all customers, newest first"
    params do
      use :pagination
      use :ordering, model: Suma::Customer
      use :searchable
    end
    get do
      ds = Suma::Customer.dataset
      if (email_like = search_param_to_sql(params, :email))
        name_like = search_param_to_sql(params, :name)
        phone_like = phone_search_param_to_sql(params)
        ds = ds.where(email_like | name_like | phone_like)
      end

      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: Suma::AdminAPI::CustomerEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup_customer!
          (customer = Suma::Customer[params[:id]]) or not_found!
          return customer
        end
      end

      desc "Return the customer"
      get do
        customer = lookup_customer!
        present customer, with: Suma::AdminAPI::DetailedCustomerEntity
      end

      desc "Update the customer"
      params do
        optional :name, type: String
        optional :note, type: String
        optional :email, type: String
        optional :phone, type: Integer
        optional :timezone, type: String, values: ALL_TIMEZONES
        optional :roles, type: Array[String]
      end
      post do
        customer = lookup_customer!
        fields = params
        customer.db.transaction do
          if (roles = fields.delete(:roles))
            customer.remove_all_roles
            roles.uniq.each { |r| customer.add_role(Suma::Role[name: r]) }
          end
          set_declared(customer, params)
          customer.save_changes
        end
        status 200
        present customer, with: Suma::AdminAPI::DetailedCustomerEntity
      end

      post :close do
        customer = lookup_customer!
        admin = admin_customer
        customer.db.transaction do
          customer.add_activity(
            message_name: "accountclosed",
            summary: "Admin #{admin.email} closed customer #{customer.email} account",
            subject_type: "Suma::Customer",
            subject_id: customer.id,
          )
          customer.soft_delete unless customer.soft_deleted?
        end
        status 200
        present customer, with: Suma::AdminAPI::DetailedCustomerEntity
      end
    end
  end
end
