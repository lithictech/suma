# frozen_string_literal: true

module Suma::AdminAPI::CommonEndpoints
  module MutationHelpers
    def association_class?(h, cls) = h[:class] == cls || h[:class_name] == cls.to_s
    def association_class(h) = h[:class] || Kernel.const_get(h[:class_name])

    def model_field_params(m, p)
      mp = p.dup
      mp.delete_if { |k| !m.respond_to?("#{k}=") }
      return mp
    end

    def update_model(m, orig_params, process_params: nil, save: true)
      params = orig_params.deep_symbolize_keys
      params.delete(:id)
      process_params&.call(params)
      mtype = m.class
      images = []
      to_many_assocs_and_args = []
      to_one_assocs_and_params = []
      fk_attrs = {}
      params.to_a.each do |(k, v)|
        next unless (assoc = mtype.association_reflections[k])
        params.delete(k)
        if assoc[:type].to_s.end_with?("_to_one")
          if association_class?(assoc, Suma::TranslatedText)
            fk_attrs[assoc[:name]] = Suma::TranslatedText.find_or_create(**v)
          elsif association_class?(assoc, Suma::Address)
            fk_attrs[assoc[:name]] = Suma::Address.lookup(v)
          elsif association_class?(assoc, Suma::Image)
            uf = Suma::UploadedFile.create_from_multipart(v)
            images << Suma::Image.new(uploaded_file: uf)
          elsif v.key?(:id)
            fk_attrs[assoc[:key]] = v[:id]
          else
            to_one_assocs_and_params << [assoc, v]
          end
        else
          to_many_assocs_and_args << [assoc, v]
        end
      end
      m.set(model_field_params(m, params))
      m.set(fk_attrs)
      save_or_error!(m) if save
      images.each { |im| m.add_image(im) }
      to_one_assocs_and_params.each do |(assoc, mparams)|
        fk_model = association_class(assoc).find_or_create_or_find(assoc[:key] => m.id)
        update_model(fk_model, mparams)
      end
      to_many_assocs_and_args.each do |(assoc, args)|
        unseen_children = m.send(assoc[:name]).to_h { |am| [am.id, am] }
        args.each do |mparams|
          assoc_model = if (assoc_model_id = mparams.delete(:id))
                          # Submitting as form encoding, like when using an image, turns everything into a string
                          assoc_model_id = assoc_model_id.to_i
                          unseen_children.delete(assoc_model_id)
                          association_class(assoc)[assoc_model_id]
          else
            association_class(assoc).new
          end
          update_model(assoc_model, mparams, save: false)
          m.send(assoc[:add_method], assoc_model)
        end
        unseen_children.values.each(&:destroy)
        m.associations.delete(assoc[:name])
      end
    end
  end

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

  def self.create(route_def, model_type, entity, process_params: nil, &)
    route_def.instance_exec do
      helpers MutationHelpers
      yield
      post :create do
        model_type.db.transaction do
          m = model_type.new
          update_model(
            m,
            params,
            process_params:,
          )
          created_resource_headers(m.id, m.admin_link)
          status 200
          present m, with: entity
        end
      end
    end
  end

  def self.update(route_def, model_type, entity, process_params: nil, &)
    route_def.instance_exec do
      route_param :id, type: Integer do
        helpers MutationHelpers
        yield
        post do
          model_type.db.transaction do
            (m = model_type[params[:id]]) or forbidden!
            update_model(
              m,
              params,
              process_params:,
            )
            created_resource_headers(m.id, m.admin_link)
            status 200
            present m, with: entity
          end
        end
      end
    end
  end
end
