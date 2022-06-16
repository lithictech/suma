# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"
require "pg"
require "sequel"
require "tsort"

require "suma"
require "suma/postgres"
require "suma/postgres/model_utilities"

# Initialize the Suma::Postgres::Model class as an abstract model class (i.e.,
# without a default dataset). This prevents it from looking for a table called
# `models`, and makes inheriting it more straightforward.
# Thanks to Michael Granger and Jeremy Evans for the suggestion.
Suma::Postgres::Model = Class.new(Sequel::Model)
Suma::Postgres::Model.def_Model(Suma::Postgres)

class Suma::Postgres::Model
  include Appydays::Configurable
  extend Suma::Postgres::ModelUtilities
  include Appydays::Loggable

  configurable(:suma_db) do
    setting :uri, "postgres:/suma_test", key: "DATABASE_URL"

    # The number of (Float) seconds that should be considered "slow" for a
    # single query; queries that take longer than this amount of time will be logged
    # at `warn` level.
    setting :slow_query_seconds, 0.01

    ##
    # The maximum number of connections to use in the Sequel pool
    # Ref: http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-General+connection+options
    setting :max_connections, 4

    # rubocop:disable Naming/VariableNumber
    setting :encryption_key_0, "Tc3X6zkxXgZfHE81MFz2EILStV++BuQY"
    # rubocop:enable Naming/VariableNumber

    after_configured do
      options = {
        max_connections: self.max_connections,
      }
      self.logger.debug "Connecting to %s with options: %p" % [self.uri, options]
      self.db = Sequel.connect(self.uri, options)
    end
  end

  # Add one or more extension +modules+ to the receiving class. This allows subsystems
  # like Orders, etc. to decorate models outside of their purview
  # without introducing unnecessary dependencies.
  #
  # Each one of the given +modules+ will be included in the receiving model class, and
  # if it also contains a constant called ClassMethods, the model class will be
  # also be extended with it.
  #
  # @example Add order methods to Suma::Member
  #
  #   module Suma::Orders::CustomerExtensions
  #
  #       # Add some associations for Order models
  #       def included( model )
  #           super
  #           model.one_to_many :orders, Sequel[:app][:orders]
  #       end
  #
  #       def first_order
  #           self.orders.first
  #       end
  #
  #   end
  def self.add_extensions(*modules)
    self.logger.info "Adding extensions to %p: %p" % [self, modules]

    modules.each do |mod|
      include(mod)
      if mod.const_defined?(:ClassMethods)
        submod = mod.const_get(:ClassMethods)
        self.extend(submod)
      end
      if mod.const_defined?(:PrependedMethods)
        submod = mod.const_get(:PrependedMethods)
        prepend(submod)
      end
    end
  end

  plugin :column_encryption do |enc|
    enc.key 0, self.encryption_key_0
  end
end
