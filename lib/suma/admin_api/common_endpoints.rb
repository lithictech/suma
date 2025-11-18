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
      # mparams: the model association params (or an instance of the associated model)
      cparams = orig_params.deep_symbolize_keys
      cparams.delete(:id)
      _handle_doemptyarray_params(params, cparams)
      mtype = m.class
      to_many_assocs_and_args = []
      to_one_assocs_and_params = []
      fk_attrs = {}
      caption_params = []
      cparams.to_a.each do |(k, v)|
        if k.to_s.end_with?("_caption")
          # If this is a caption field, let's make sure it points to a Suma::Image.
          # If so, we handle it specially.
          # We must use multipart form for images, which requires a top-level File object.
          # So we cannot have, for example, `{image: {file:, caption: {en: '', es: ''}}}`,
          # we must have something like `{image_file:, image_caption:}`
          # (we use `:image` instead of `:image_file` though).
          captioned_field = k.to_s.delete_suffix("_caption").to_sym
          is_image = association_class?(mtype.association_reflections[captioned_field], Suma::Image)
          if is_image
            caption_params << [captioned_field, v]
            cparams.delete(k)
            next
          end
        end
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
            to_one_assocs_and_params << [assoc, Suma::Image.new(uploaded_file: uf)]
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
        if mparams.is_a?(assoc_cls)
          # If we passed in an unsaved instance of the associated model (like a vendor's image),
          # set the reverse association (like 'mparams.vendor = m'), save it, and move on.
          m.send(:"#{assoc[:name]}=", mparams)
          mparams.save_changes
          next
        end
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
        existing_instances_by_id = m.send(assoc[:name]).to_h { |am| [am.id, am] }
        unseen_children = existing_instances_by_id.dup
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
          needs_add = !existing_instances_by_id.key?(assoc_model.id)
          needs_add ? m.send(assoc[:add_method], assoc_model) : assoc_model.save_changes
        end
        if assoc[:type] == :many_to_many
          unseen_children.each_value { |c| m.send(assoc[:remove_method], c) }
        else
          begin
            unseen_children.each_value(&:destroy)
          rescue Sequel::ForeignKeyConstraintViolation => e
            msg = "One of these resources could not be removed because it is used elsewhere. " \
                  "Please modify it instead. If you need more help, please contact a developer."
            merror!(409, msg, code: "fk_violation", more: {exception: e.message}, skip_loc_check: true)
          end
        end
      end
      caption_params.each do |(field, caption)|
        img = m.send(field)
        img.caption = Suma::TranslatedText.find_or_create(caption)
        img.save_changes
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

  def self.list(
    route_def,
    model_type,
    entity,
    exporter: Suma::Exporter::Placeholder,
    ordering_kw: {},
    ordering: nil,
    dataset: nil
  )
    route_def.instance_exec do
      params do
        use :pagination
        use :ordering, model: model_type, **ordering_kw
        use :searchable
        optional :download, type: String, values: ["csv"]
      end
      get do
        check_admin_role_access!(:read, model_type)
        ds = model_type.dataset
        if params[:search].present?
          ds = hybrid_search(ds, params)
          # Override the hybrid search ranking if an explicit ordering is passed.
          ds = order(ds, params) if param_passed?(:order_by)
        elsif ordering
          ds = self.instance_exec(ds, params, &ordering)
        else
          ds = order(ds, params)
        end
        ds = dataset.call(ds) if dataset
        if params[:download]
          csv = exporter.new(ds).to_csv
          env["api.format"] = :binary
          content_type "text/csv"
          body csv
          header["Content-Disposition"] = "attachment; filename=suma-members-export.csv"
        else
          ds = paginate(ds, params)
          present_collection ds, with: entity
        end
      end
    end
  end

  def self.get_one(route_def, model_type, entity)
    route_def.instance_exec do
      route_param :id, type: Integer do
        get do
          check_admin_role_access!(:read, model_type)
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
        check_admin_role_access!(:write, model_type)
        _throwsafe_transaction(model_type.db) do
          m = model_type.new
          # Always set this if the model supports it.
          m.created_by = admin_member if m.respond_to?(:created_by)
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
          check_admin_role_access!(:write, model_type)
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

  def self.destroy(route_def, model_type, entity, around: nil)
    around ||= ->(*, &b) { b.call }
    route_def.instance_exec do
      route_param :id, type: Integer do
        post :destroy do
          check_admin_role_access!(:write, model_type)
          (m = model_type[params[:id]]) or forbidden!
          around.call(self, m) do
            m.destroy
          end
          status 200
          present m, with: entity
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
          check_admin_role_access!(:write, model_type)
          _throwsafe_transaction(model_type.db) do
            (m = model_type[params[:id]]) or forbidden!
            params[:program_ids].each do |id|
              Suma::Program[id] or adminerror!(403, "Unknown program: #{id}")
            end
            m.program_pks = (params[:program_ids])
            m.save_changes
            m.audit_activity(
              "programchange",
              action: m.programs.map { |p| p.name.en }.join(", "),
            )
            status 200
            present m, with: entity
          end
        end
      end
    end
  end

  def self.annotated(route_def, model_type, entity)
    route_def.instance_exec do
      route_param :id, type: Integer do
        resource :notes do
          params do
            requires :content, type: String, allow_blank: false
          end
          post :create do
            check_admin_role_access!(:write, model_type)
            (m = model_type[params[:id]]) or forbidden!
            m.db.transaction do
              note = Suma::Support::Note.create(content: params[:content])
              m.add_note(note)
            end
            created_resource_headers(m.id, m.admin_link)
            status 200
            present m, with: entity
          end

          route_param :note_id, type: Integer do
            params do
              requires :content, type: String, allow_blank: false
            end
            post do
              check_admin_role_access!(:write, model_type)
              (m = model_type[params[:id]]) or forbidden!
              (note = m.notes_dataset[params[:note_id]]) or forbidden!
              note.update(content: params[:content])
              created_resource_headers(m.id, m.admin_link)
              status 200
              present m, with: entity
            end
          end
        end
      end
    end
  end
end
