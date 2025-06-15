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
    def db = Suma::Webhookdb.connection
  end
end
