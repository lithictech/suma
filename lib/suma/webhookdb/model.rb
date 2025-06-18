# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"

require "suma/webhookdb"
require "suma/postgres/model_utilities"

# See suma/postgres/model.rb
Suma::Webhookdb::Model = Class.new(Sequel::Model)
Suma::Webhookdb::Model.def_Model(Suma::Webhookdb)

class Suma::Webhookdb::Model
  include Appydays::Loggable
  extend Suma::Postgres::ModelUtilities

  class << self
    def db
      # If models are enabled, assume the configured tables existing in WebhookDB.
      # If models are not enabled, we can mock out the connection with a mock:// database connection
      # using Postgres semantics. We'll never get any results, so it should be okay.
      return Suma::Webhookdb.connection if Suma::Webhookdb.models_enabled
      return @_mock_db ||= Sequel.connect("mock://", host: "postgres")
    end

    def read_only? = true
  end
end
