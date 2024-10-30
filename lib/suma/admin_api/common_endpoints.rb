# frozen_string_literal: true

require "suma/admin_api"
require "suma/admin_api/access"

module Suma::AdminAPI::CommonEndpoints
  class ThrowNeedsRollback < StandardError
    attr_reader :thrown

    def initialize(thrown)
      @thrown = thrown
      super("for flow control :(")
    end
  end

  module MutationHelpers
    def association_class?(h, cls) = h[:class] == cls || h[:class_name] == cls.to_s
    def association_class(h) = h[:class] || Kernel.const_get(h[:class_name])

    def model_field_params(m, p)
      mp = p.dup
      mp.delete_if { |k| !m.respond_to?(:"#{k}=") }
      return mp
    end

    def update_model(m, orig_params, save: true)
      # orig_params: the declared parameters passed in
      # cparams: the cleaned orig_params
      # mparams: the model association params
      cparams = orig_params.deep_symbolize_keys
      cparams.delete(:id)
      _handle_doemptyarray_params(params, cparams)
      mtype = m.class
      images = []
      to_many_assocs_and_args = []
      to_one_assocs_and_params = []
      fk_attrs = {}
      cparams.to_a.each do |(k, v)|
        next unless (assoc = mtype.association_reflections[k])
        cparams.delete(k)
        if assoc[:type].to_s.end_with?("_to_one")
          if v.nil?
            fk_attrs[assoc[:name]] = nil
          elsif association_class?(assoc, Suma::TranslatedText)
            fk_attrs[assoc[:name]] = Suma::TranslatedText.find_or_create(**v)
          elsif association_class?(assoc, Suma::Address)
            fk_attrs[assoc[:name]] = Suma::Address.lookup(v)
          elsif association_class?(assoc, Suma::Image)
            uf = Suma::UploadedFile.create_from_multipart(v)
            images << Suma::Image.new(uploaded_file: uf)
          elsif v.key?(:id) && v.one?
            # If we're passing in a hash like {id:}, we just want to replace the FK.
            # If the hash includes more fields, it'll get caught by the else which replaces
            # and updates the association.
            # The params block will determine whether 1) we are only setting :id,
            # like assigning a Vendor to a Product, or
            # 2) we're also updating the FK, like updating Inventory on a Product.
            fk_attrs[assoc[:key]] = v[:id]
          else
            to_one_assocs_and_params << [assoc, v]
          end
        else
          to_many_assocs_and_args << [assoc, v]
        end
      end
      m.set(model_field_params(m, cparams))
      m.set(fk_attrs)
      save_or_error!(m) if save
      images.each { |im| m.add_image(im) }
      to_one_assocs_and_params.each do |(assoc, mparams)|
        # We're updating a child resource through its parent.
        #
        # This can go in the normal direction, where the child has a parent id.
        # For example, a product inventory has a product_id pointing to product.
        # When we update the product, we can also create/update the inventory.
        # These are always one_to_one from the POV of the model here (parent).
        #
        # But it can also go in the 'reverse' direction,
        # where we're updating a 'child' and its parent at the same time.
        # For example, a member (which we usually think of as a parent) has a legal_entity_id.
        # When we update the member, we also want to update the legal entity is 'owns'.
        # These are always many_to_one from the POV of the model here (child).
        #
        # Logically we handle them both similarly, with the difference being where the FK is set.

        assoc_cls = association_class(assoc)
        fk_model = if (passed_fk_pk = mparams.delete(assoc_cls.primary_key))
                     assoc_cls.find!(assoc_cls.primary_key => passed_fk_pk)
        else
          m.send(assoc[:name])
        end
        fk_model ||= assoc_cls.new
        if assoc[:type] == :one_to_one
          # fk_model (child) has an FK to m (parent)
          # This will set child.parent_id to parent.id
          m.set(assoc[:name] => fk_model)
        end
        update_model(fk_model, mparams)
        next unless assoc[:type] == :many_to_one
        # m (child) has an FK to fk_model (parent)
        # Set it now, that fk_model has an ID for sure.
        m.update(assoc[:name] => fk_model)
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
        begin
          unseen_children.each_value(&:destroy)
        rescue Sequel::ForeignKeyConstraintViolation => e
          msg = "One of these resources could not be removed because it is used elsewhere. " \
                "Please modify it instead. If you need more help, please contact a developer."
          merror!(409, msg, code: "fk_violation", more: {exception: e.message}, skip_loc_check: true)
        end
      end
    end

    # Roll back the transaction if an error is returned by the block.
    # Because the block can catch a database error and call `error!` (which calls `throw(:error, {...})` in Grape),
    # such as due to an FK violation,
    # the exception doesn't bubble up to Sequel's DB#transaction.
    # This means DB#transaction tries to commit a transaction, but if there is a database error,
    # the commit fails.
    #
    # This code has to go through some workarounds to:
    # - Catch a throw(:error)
    # - Re-raise it so Sequel sees the exception and rolls back the transaction
    # - Catch the exception, and re-throw the error, so Grape sees it.
    #
    # In theory, this code should be moved to more general helpers-
    # there is some risk that we could be calling `error!` in our services,
    # and getting outer transactions committed.
    # In practice this is very rare, and the complexity of model updates in CommonEndpoints is the first time
    # it's come up. But still, we should consider using this instead of normal db.transaction in the API.
    def _throwsafe_transaction(db, &)
      db.transaction do
        caught = catch(:error, &)
        raise ThrowNeedsRollback, caught if status >= 400
        caught
      end
    rescue ThrowNeedsRollback => e
      throw :error, e.thrown
    end

    def _handle_doemptyarray_params(all_params, cparams)
      suffix = "_doemptyarray"
      suffix_len = suffix.length
      all_params.each do |k, v|
        next unless k.end_with?(suffix) && v
        raw_array_key = k[...-suffix_len]
        cparams[raw_array_key.to_sym] = []
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
        access = Suma::AdminAPI::Access.read_key(model_type)
        check_role_access!(admin_member, :read, access)
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
          access = Suma::AdminAPI::Access.read_key(model_type)
          check_role_access!(admin_member, :read, access)
          (m = model_type[params[:id]]) or forbidden!
          present m, with: entity
        end
      end
    end
  end

  def self.create(route_def, model_type, entity, around: nil, &)
    around ||= ->(*, &b) { b.call }
    route_def.instance_exec do
      helpers MutationHelpers
      yield
      post :create do
        access = Suma::AdminAPI::Access.write_key(model_type)
        check_role_access!(admin_member, :write, access)
        _throwsafe_transaction(model_type.db) do
          m = model_type.new
          around.call(self, m) do
            # Must be done INSIDE of 'around' in case it modifies `params`.
            dparams = declared_and_provided_params(params)
            update_model(m, dparams)
          end
          created_resource_headers(m.id, m.admin_link)
          status 200
          present m, with: entity
        end
      end
    end
  end

  def self.update(route_def, model_type, entity, around: nil, &)
    around ||= ->(*, &b) { b.call }
    route_def.instance_exec do
      route_param :id, type: Integer do
        helpers MutationHelpers
        yield
        post do
          access = Suma::AdminAPI::Access.write_key(model_type)
          check_role_access!(admin_member, :write, access)
          _throwsafe_transaction(model_type.db) do
            (m = model_type[params[:id]]) or forbidden!
            around.call(self, m) do
              # Must be done INSIDE of 'around' in case it modifies `params`.
              dparams = declared_and_provided_params(params)
              update_model(m, dparams)
            end
            created_resource_headers(m.id, m.admin_link)
            status 200
            present m, with: entity
          end
        end
      end
    end
  end

  def self.programs_update(route_def, model_type, entity)
    route_def.instance_exec do
      route_param :id, type: Integer do
        helpers MutationHelpers
        params do
          requires :program_ids, type: Array[Integer], coerce_with: Suma::Service::Types::CommaSepArray[Integer]
        end
        post :programs do
          access = Suma::AdminAPI::Access.write_key(model_type)
          check_role_access!(admin_member, :write, access)
          _throwsafe_transaction(model_type.db) do
            (m = model_type[params[:id]]) or forbidden!
            params[:program_ids].each do |id|
              Suma::Program[id] or adminerror!(403, "Unknown program: #{id}")
            end
            m.program_pks = (params[:program_ids])
            m.save_changes
            summary = m.programs.map { |p| p.name.en }.join(", ")
            admin_member.add_activity(
              message_name: "programchange",
              summary: "Admin #{admin_member.email} modified programs of #{m.model}[#{m.id}]: #{summary}",
              subject_type: m.model,
              subject_id: m.id,
            )
            status 200
            present m, with: entity
          end
        end
      end
    end
  end
end
