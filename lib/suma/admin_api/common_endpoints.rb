# frozen_string_literal: true

module Suma::AdminAPI::CommonEndpoints
  def self.list(route_def, model_type, entity, search_params: [], translation_search_params: [])
    # TODO: translation join doesn't work for multiple search terms
    raise ArgumentError("translation join does not work for multiple search terms") if
      translation_search_params.length > 1

    route_def.instance_exec do
      params do
        use :pagination
        use :ordering, model: model_type
        use :searchable
      end
      get do
        ds = model_type.dataset
        search_exprs = search_params.map { |p| search_param_to_sql(params, p) }
        translation_search_params.each do |p|
          en_like = search_param_to_sql(params, :"#{p}_en")
          next unless en_like
          es_like = search_param_to_sql(params, :"#{p}_es")
          search_exprs << en_like
          search_exprs << es_like
          ds = ds.translation_join(p, [:en, :es])
        end
        ds = ds.reduce_expr(:|, search_exprs)
        ds = order(ds, params)
        ds = paginate(ds, params)
        present_collection ds, with: entity
      end
    end
  end

  def self.get_one(route_def, model_type, entity)
    route_def.instance_exec do
      route_param :id, type: Integer do
        get do
          (m = model_type[params[:id]]) or forbidden!
          present m, with: entity
        end
      end
    end
  end

  def self.create(route_def, model_type, entity, &)
    route_def.instance_exec do
      yield
      post :create do
        model_type.db.transaction do
          m = model_type.create(params)
          created_resource_headers(m.id, m.admin_link)
          status 200
          present m, with: entity
        end
      end
    end
  end
end
