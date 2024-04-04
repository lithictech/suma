# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"

require "suma/analytics"
require "suma/postgres/model_utilities"

# See suma/postgres/model.rb
Suma::Analytics::Model = Class.new(Sequel::Model)
Suma::Analytics::Model.def_Model(Suma::Analytics)

class Suma::Analytics::Model
  include Appydays::Configurable
  include Appydays::Loggable
  extend Suma::Postgres::ModelUtilities

  class RowMismatch < StandardError; end

  configurable(:analytics_database) do
    setting :uri, ENV.fetch("DATABASE_URL", "postgres://suma_analytics_test"), key: "ANALYTICS_DATABASE_URL"
    setting :pool_timeout, 10
    setting :max_connections, 4
    after_configured do
      options = {
        logger: [self.logger],
        sql_log_level: :debug,
        max_connections: self.max_connections,
        pool_timeout: self.pool_timeout,
      }
      db = Sequel.connect(self.uri, options)
      self.db = db
    end
  end

  def self.inherited(subclass)
    super
    subclass.extend(ClassMethods)
  end

  module ClassMethods
    def unique_key(sym=nil)
      @unique_key = sym unless sym.nil?
      return @unique_key
    end

    # Declare that this class denormalizes the given class (a descendant of +Suma::Postgres::Model+)
    # using the given method.
    #
    # @param transactional_model_class [Class] Like +Suma::Member+.
    # @param with [Symbol,Proc] Like +member_to_rows+. Must return a hash of the row to upsert,
    #   or an array of row hashes to upsert. Every row hash must include the +unique_key+,
    #   used for conditional upserting.
    def denormalize(transactional_model_class, with:)
      self.denormalizers[transactional_model_class] = with
    end

    def denormalizers = (@denormalizers ||= {})

    # @return [Array<Class>]
    def denormalizing_from = self.denormalizers.keys

    # Return true if this model handles instances of the given transactional model class.
    # @param oltp_class [Class]
    def denormalize_from?(oltp_class) = self.denormalizers.key?(oltp_class)

    # Given a model, for which +can_handle?+ on its class returned true,
    # call the handler for it and return its rows.
    def to_rows(oltp_model)
      h = self.denormalizers[oltp_model.class] or raise KeyError, "#{self} has no denormalizer for #{oltp_model.class}"
      handler = h.is_a?(Symbol) ? self.method(h) : h
      rows = handler.call(oltp_model)
      rows = Suma.as_ary(rows)
      unique_key = self.unique_key
      unless (_rows_ok = rows.all? { |r| r.key?(unique_key) })
        msg = "All rows need a key with the table's unique key, used for upsert: #{unique_key}"
        raise Suma::InvalidPostcondition, msg
      end
      return rows
    end

    def upsert_rows(*rows)
      unique_key = self.unique_key
      combined_rows_by_unique_id = {}
      rows.each do |row|
        key = row.fetch(unique_key)
        combined_rows_by_unique_id[key] ||= {}
        combined_rows_by_unique_id[key].merge!(row)
      end
      combined_rows = combined_rows_by_unique_id.values
      columns = combined_rows.first.keys.sort
      combined_rows[1..].each do |r|
        next if columns == r.keys.sort
        msg = "All rows in upsert_rows must have a consistent schema.\n" \
              "Row with #{unique_key}=#{r.fetch(unique_key)} has the keys: #{r.keys.sort}\n" \
              "Expected keys: #{columns}"
        raise RowMismatch, msg
      end
      updating = combined_rows.first.each_with_object({}) { |(c, _), h| h[c] = Sequel[:excluded][c] }
      self.dataset.insert_conflict(
        target: unique_key,
        update: updating,
      ).multi_insert(combined_rows)
    end

    def destroy_from(oltp_class)
      @destroy_from = oltp_class
    end

    def destroy_from?(oltp_class) = oltp_class == @destroy_from

    def destroy_rows(oltp_ids)
      oltp_ids = Suma.as_ary(oltp_ids)
      self.dataset.where(self.unique_key => oltp_ids).delete
    end
  end
end
