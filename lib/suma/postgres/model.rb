# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"
require "pg"
require "sequel"
require "tsort"

require "suma"
require "suma/postgres"
require "suma/postgres/model_utilities"
require "suma/postgres/model_pubsub"

# Initialize the Suma::Postgres::Model class as an abstract model class (i.e.,
# without a default dataset). This prevents it from looking for a table called
# `models`, and makes inheriting it more straightforward.
# Thanks to Michael Granger and Jeremy Evans for the suggestion.
Suma::Postgres::Model = Class.new(Sequel::Model)
Suma::Postgres::Model.def_Model(Suma::Postgres)

class Suma::Postgres::Model
  include Appydays::Configurable
  extend Suma::Postgres::ModelUtilities
  extend Suma::Postgres::ModelPubsub
  include Appydays::Loggable

  plugin(:json_serializer)
  plugin(:many_through_many)
  plugin(:tactical_eager_loading)
  plugin(:update_or_create)
  plugin(:validation_helpers)

  configurable(:suma_db) do
    setting :uri, "postgres:/suma_test", key: "DATABASE_URL"

    setting :extension_schema, "public"

    # The number of (Float) seconds that should be considered "slow" for a
    # single query; queries that take longer than this amount of time will be logged
    # at `warn` level.
    setting :slow_query_seconds, 0.01

    setting :pool_timeout, 10

    # The maximum number of connections to use in the Sequel pool
    # Ref: http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-General+connection+options
    setting :max_connections, 4

    # rubocop:disable Naming/VariableNumber
    setting :encryption_key_0, "Tc3X6zkxXgZfHE81MFz2EILStV++BuQY"
    # rubocop:enable Naming/VariableNumber

    after_configured do
      options = {
        logger: [self.logger],
        sql_log_level: :debug,
        max_connections: self.max_connections,
        pool_timeout: self.pool_timeout,
        log_warn_duration: self.slow_query_seconds,
      }
      db = Sequel.connect(self.uri, options)
      db.extension(:pagination)
      db.extension(:pg_json)
      db.extension(:pg_inet)
      db.extension(:pg_array)
      db.extension(:pg_streaming)
      db.extension(:pg_range)
      db.extension(:pg_interval)
      db.extension(:pretty_table)
      self.db = db
    end
  end

  def self.extensions
    return [
      "citext",
      "vector",
      "pg_stat_statements",
      "pgcrypto",
      "btree_gist",
      "pg_trgm",
      "vector",
    ]
  end

  plugin :column_encryption do |enc|
    enc.key 0, self.encryption_key_0
  end
end
