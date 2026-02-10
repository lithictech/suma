# frozen_string_literal: true

require "amigo"
require "tsort"
require "pg"
require "suma/postgres"

# A collection of utilities that can be added to model superclasses.
module Suma::Postgres::ModelUtilities
  include TSort

  # Extension callback -- register the +model_class+ with Suma::Postgres.
  def self.extended(model_class)
    super

    model_class.plugin(:subclasses)

    model_class.include(Appydays::Loggable)
    model_class.extend(ClassMethods)
    model_class.include(InstanceMethods)
    model_class.dataset_module(DatasetMethods)

    Suma::Postgres.register_model_superclass(model_class)
  end

  module ClassMethods
    def anonymous? = self.name.blank? || self.name.start_with?("Sequel::_Model")

    # The application name, set on database connections.
    attr_reader :appname

    # Set the PostgreSQL application name to +name+ to allow per-application connection
    # tracking and other fun stuff.
    # @param name [String]
    def appname=(name)
      @appname = name
      self.update_connection_appname
    end

    # Set the connection's application name if there is one.
    def update_connection_appname
      return unless self.db
      self.logger.debug "Setting application name to %p" % [self.appname]
      self.db.synchronize do |conn|
        escaped = conn.escape_string(self.appname)
        conn.exec("SET application_name TO '%s'" % [escaped])
      end
    end

    # Some model classes just map Sequel models onto readonly connections.
    # These models should override this method and return true.
    def read_only? = false

    # Return the Array of the schemas used by all descendents of the receiving
    # model class.
    # @return [Array<String>]
    def all_loaded_schemas = self.descendents.map(&:schema_name).uniq.compact

    # Create a new schema named +name+ (if it doesn't already exist).
    # @param name [Symbol]
    def create_schema(name)
      self.db.create_schema(name, if_not_exists: true)
    end

    # Create the schema named +name+, dropping any previous schema by the same name.
    # @param name [Symbol]
    def create_schema!(name)
      self.drop_schema!(name)
      self.create_schema(name)
    end

    # Drop the empty schema named +name+ (if it exists).
    # @param name [Symbol]
    def drop_schema(name)
      self.db.drop_schema(name, if_exists: true)
    end

    # Drop the schema named +name+ and all of its tables.
    # @param name [Symbol]
    def drop_schema!(name)
      self.db.drop_schema(name, if_exists: true, cascade: true)
    end

    # Returns +true+ if a schema named +name+ exists.
    # @param name [#to_s]
    def schema_exists?(name=self.schema_name)
      ds = self.db[Sequel[:pg_catalog][:pg_namespace]].
        filter(nspname: name.to_s).
        select(:nspname)

      return !!ds.first
    end

    # Return the name of the schema the receiving class is in.
    # @return [String]
    def schema_name
      schemaname, = self.db.send(:schema_and_table, self.table_name)
      return schemaname
    end

    # @return [Sequel::SQL::Expression]
    def now_sql = Suma::Postgres.now_sql

    # Name of the extension schema. Usually 'public' but should be 'heroku_ext' on Heroku.
    # @return [String]
    def extension_schema
      raise NotImplementedError, "must be overridden by model class" if self.extensions.any?
      return ""
    end

    # List of names of extensions, like 'citext'.
    # @return [Array<String>]
    def extensions = []

    def install_all_extensions
      self.extensions.each do |ext|
        self.db.execute("CREATE EXTENSION IF NOT EXISTS #{ext} WITH SCHEMA #{self.extension_schema}")
      end
    end

    # TSort API -- yield each model class.
    def tsort_each_node(&)
      self.descendents.select(&:name).each(&)
    end

    # TSort API -- yield each of the given +model_class+'s dependent model classes.
    def tsort_each_child(model_class)
      # Include (non-anonymous) parents other than Model
      non_anon_parents = model_class.ancestors[1..].
        select { |cl| cl < self }.
        select(&:name)
      # rubocop:disable Style/ExplicitBlockArgument
      non_anon_parents.each do |parentclass|
        yield(parentclass)
      end
      # rubocop:enable Style/ExplicitBlockArgument

      # Include associated classes for which this model class's table has a
      # foreign key
      model_class.association_reflections.each_value do |config|
        next if config[:polymorphic]
        associated_class = Object.const_get(config[:class_name])
        yield(associated_class) if config[:type] == :many_to_one
      end
    end
  end

  # Like +find_or_create+, but will +find+ again if the +create+
  # call fails due to a +Sequel::UniqueConstraintViolation+,
  # which is usually caused by a race condition.
  def find_or_create_or_find(params, &)
    # Set a savepoint, because the DB error will abort the current transaction.
    self.db.transaction(savepoint: true) do
      return self.find_or_create(params, &)
    end
  rescue Sequel::UniqueConstraintViolation
    return self.find(params)
  end

  def find!(arg)
    if arg.is_a?(Integer)
      x = self.with_pk(arg)
      ds = self.where(self.primary_key_hash(arg))
    else
      ds = self.where(arg)
      x = ds.first
    end
    return x if x
    raise Suma::Postgres::NoMatchingRow, ds
  end

  # Temporarily set a field on the class.
  # Usually used to turn off something like strict_param_setting within a block.
  def with_setting(key, value)
    old = self.send(key)
    begin
      self.send(:"#{key}=", value)
      return yield
    ensure
      self.send(:"#{key}=", old)
    end
  end

  module InstanceMethods
    # Return a human-readable representation of the object as a String suitable for debugging.
    def inspect
      values = self.values.reject do |k, v|
        v.blank? || k.to_s.end_with?("_currency")
      end
      begin
        encrypted = self.class.send(:column_encryption_metadata).to_set { |(col, _)| col.to_s }
      rescue NoMethodError
        encrypted = Set.new
      end
      begin
        vector_col = self.class.send(:hybrid_search_vector_column).to_s
      rescue NoMethodError
        nil
      end
      values = values.map do |(k, v)|
        k = k.to_s
        v = if v.is_a?(Time)
              self.inspect_time(v)
        elsif v.respond_to?(:db_type) && v.db_type.to_s == "tstzrange"
          "%s%s...%s%s" % [
            v.exclude_begin? ? "(" : "[",
            v.begin ? self.inspect_time(v.begin) : "nil",
            v.end ? self.inspect_time(v.end) : "nil",
            v.exclude_end? ? ")" : "]",
          ]
        elsif k.end_with?("_cents")
          accessor = k.match(/^([a-z_]+)_cents/)[1]
          if self.respond_to?(accessor)
            k = accessor
            self.send(accessor).format
          else
            v.inspect
          end
        elsif k.end_with?("_base64")
          "(#{v.size})"
        elsif encrypted.include?(k)
          # Render encrypted fields as xyz...abc, or if a URL, hide the user/password.
          unenc = self.send(k)
          safe = nil
          if unenc.include?("://")
            begin
              uri = URI(unenc)
            rescue URI::InvalidURIError
              nil
            else
              uri.user = "*"
              uri.password = "*"
              safe = uri.to_s
            end
          end
          safe ||= "#{unenc[..2]}...#{unenc[-3..]}"
          safe.inspect
        elsif k == vector_col
          # The vector array may already be encoded to a string, so just return the db column type, like 'vector(384)'.
          self.class.db_schema.fetch(vector_col.to_sym).fetch(:db_type)
        else
          v.inspect
        end
        "#{k}: #{v}"
      end
      return "#<%p %s>" % [self.class, values.join(", ")]
    end

    alias to_s inspect if ENV["DEBUGGER_HOST"]

    # @return [String]
    def inspect_time(t) = t.in_time_zone(Time.zone).strftime("%Y-%m-%d %H:%M:%S")

    # Return the objects validation errors as full messages joined with commas.
    # @return [String]
    def error_messages = self.errors.full_messages.join(", ")

    # Take an exclusive lock on the receiver, ensuring nothing else has updated the object in the meantime.
    # If the updated_at changed from what's on the receiver, to after it acquired the lock, raise LockFailed.
    # Save changes and touch updated_at after calling the given block.
    def resource_lock!
      raise LocalJumpError unless block_given?
      self.db.transaction do
        old_updated = self.round_time(self.updated_at)
        self.lock!
        new_updated = self.round_time(self.updated_at)
        raise Suma::LockFailed if old_updated != new_updated
        result = yield(self)
        self.updated_at = Time.now
        self.save_changes
        return result
      end
    end

    # Round +Time+ t to remove nanoseconds, since Postgres can only store microseconds.
    # @return [Time]
    protected def round_time(t)
      return nil if t.nil?
      return t.change(nsec: t.usec * 1000)
    end

    # @return [Sequel::SQL::Expression]
    protected def now_sql = Suma::Postgres.now_sql

    # Return the first association with a non-nil value.
    # This is usually the ORM side of a Sequel.unambiguous_constraint.
    #
    # @param assocs [Array<Symbol>]
    # @return [Sequel::Model]
    def unambiguous_association(assocs)
      assocs.each do |assoc|
        v = self.send(assoc)
        return v unless v.nil?
      end
      return nil
    end

    # Return the first association name with a non-nil value.
    #
    # @param assocs [Array<Symbol>]
    # @return [Symbol]
    def unambiguous_association_name(assocs)
      assocs.each do |assoc|
        return assoc if self.send(assoc)
      end
      return nil
    end

    # Set the relevant association field by finding the first with the same type as v,
    # and assigning to it. All other assocs get nil assigned.
    # If v is not a supported type, raise a TypeError.
    #
    # @param assocs [Array<Symbol>]
    # @param v [Sequel::Model]
    def set_ambiguous_association(assocs, v)
      if v.nil?
        assocs.each do |assoc|
          self.send("#{assoc}=", nil)
        end
        return
      end
      assocs.each do |assoc|
        details = self.class.association_reflections[assoc]
        type_match = details[:class_name] == v.class.name
        next unless type_match
        assocs.each do |other|
          next if other == assoc
          self.send("#{other}=", nil)
        end
        self.send("#{assoc}=", v)
        # rubocop:disable Lint/NonLocalExitFromIterator
        return
        # rubocop:enable Lint/NonLocalExitFromIterator
      end
      raise TypeError, "invalid association type: #{v.class}(#{v})"
    end
  end

  module DatasetMethods
    def find!(arg=nil)
      if arg.nil?
        ds = self
        x = ds.first
      elsif arg.is_a?(Integer)
        x = self.with_pk(arg)
        ds = self.where(self.model.primary_key_hash(arg))
      else
        ds = self.where(arg)
        x = ds.first
      end
      return x if x
      raise Suma::Postgres::NoMatchingRow, ds
    end

    # Helper for applying multiple conditions for Sequel, where some can be nil.
    def reduce_expr(op_symbol, operands, method: :where)
      return self if operands.blank?
      present_ops = operands.select(&:present?)
      return self if present_ops.empty?
      full_op = present_ops.reduce(&op_symbol)
      return self.send(method, full_op)
    end

    # Call a block for each row in a dataset.
    # This is the same as paged_each or use_cursor.each, except that for each page,
    # rows are re-fetched using self.where(primary_key => [pks]).all to enable eager loading.
    #
    # @param page_size [Integer] Size of each page. Smaller uses less memory.
    # @param order [Symbol] Column to order by. Default to primary key.
    # @param yield_page [true,false] If true, yield the page to the block, rather than individual rows.
    #   Helpful when bulk processing.
    #
    # (Note that paged_each does not do eager loading, which makes enumerating model associations very slow)
    def each_cursor_page(page_size: 500, order: nil, yield_page: false, &block)
      raise LocalJumpError unless block
      raise "dataset requires a use_cursor method, class may need `extension(:pagination)`" unless
        self.respond_to?(:use_cursor)
      model = self.model
      pk = model.primary_key
      order ||= pk
      current_chunk_pks = []
      order = [order] unless order.respond_to?(:to_ary)
      self.naked.select(pk).order(*order).use_cursor(rows_per_fetch: page_size, hold: true).each do |row|
        current_chunk_pks << row[pk]
        next if current_chunk_pks.length < page_size
        page = model.where(pk => current_chunk_pks).order(*order).all
        current_chunk_pks.clear
        yield_page ? yield(page) : page.each(&block)
      end
      remainder = model.where(pk => current_chunk_pks).order(*order).all
      yield_page ? yield(remainder) : remainder.each(&block)
    end

    # See each_cursor_page, but takes an additional action on each chunk of returned rows.
    # The action is called with pages of return values from the block when a page is is reached.
    # Each call to action should return nil, a result, or an array of results (nil results are ignored).
    #
    # The most common case is for ETL: process one dataset, map it in a block to return new row values,
    # and multi_insert it into a different table.
    def each_cursor_page_action(action:, page_size: 500, order: :id)
      raise LocalJumpError unless block_given?
      returned_rows_chunk = []
      self.each_cursor_page(page_size:, order:) do |instance|
        new_row = yield(instance)
        next if action.nil? || new_row.nil?
        new_row.respond_to?(:to_ary) ? returned_rows_chunk.concat(new_row) : returned_rows_chunk.push(new_row)
        if returned_rows_chunk.length >= page_size
          action.call(returned_rows_chunk)
          returned_rows_chunk.clear
        end
      end
      action&.call(returned_rows_chunk)
    end

    # Reselect is shorthandle for "ds.select(Sequel[ds.model.table_name][Sequel.lit("*")])".
    # This is useful after a join that is used in the query, but we only want to return the original model.
    def reselect
      return self.select(Sequel[self.model.table_name][Sequel.lit("*")])
    end
  end
end
