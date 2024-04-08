# frozen_string_literal: true

require "suma/postgres"
require "suma/spec_helpers"
require "suma/webhookdb"

# Some helper functions for testing. Usage:
#
#    # in spec/spec_helper.rb
#    RSpec.configure do |c|
#      c.include( Suma::SpecHelpers::Postgres )
#    end
#
#    # in my_class_spec.rb; mark an example as needing database setup
#    describe MyClass, db: true do
#    end
#
module Suma::SpecHelpers::Postgres
  extend Suma::MethodUtilities

  # Pathname constants
  BASEDIR = Pathname(__FILE__).dirname.parent
  SPECDIR = BASEDIR + "spec"
  DATADIR = SPECDIR + "data"

  SNIFF_LEAKY_TESTS = false

  Suma::Postgres.register_model("suma/postgres/testing_pixie")

  ### Inclusion callback -- install some hooks
  def self.included(context)
    context.before(:each) do |example|
      Suma::Postgres.unsafe_skip_transaction_check = true if example.metadata[:no_transaction_check]
      Suma::Postgres.do_not_defer_events = true if example.metadata[:do_not_defer_events]
    end

    context.around(:each) do |example|
      puts example.metadata[:full_description] if SNIFF_LEAKY_TESTS
      setting = example.metadata[:db]
      if setting && setting != :no_transaction
        Suma::SpecHelpers::Postgres.wrap_example_in_transactions(example)
      else
        Suma::Postgres.logger.debug "Running spec without a transaction"
        example.run
      end
      has_leaked = SNIFF_LEAKY_TESTS && (
        !Suma::Member.empty? ||
          !Suma::TranslatedText.empty?
      )
      if has_leaked
        puts "Database is not cleaned up, failing for diagnosis."
        puts "Check this or the spec that ran before: #{example.metadata[:full_description]}"
        exit
      end
    end

    context.after(:each) do |example|
      Suma::Postgres.do_not_defer_events = false if example.metadata[:do_not_defer_events]
      Suma::Postgres.unsafe_skip_transaction_check = false if example.metadata[:no_transaction_check]

      truncate_all if example.metadata[:db] == :no_transaction
    end

    super
  end

  ### Run the specified +example+ in the context of a transaction for each loaded
  ### model superclass. Raises if any of the loaded superclasses aren't
  ### configured.
  def self.wrap_example_in_transactions(example)
    txn_classes = Suma::Postgres.model_superclasses
    txn_classes.each do |txn_class|
      next if txn_class.db
      raise "No database connection for %p configured! Add a %s section to the test config." %
        [txn_class, txn_class.config_key]
    end

    dbs = txn_classes.map(&:db) + [Suma::Webhookdb.connection]
    wrapped_proc = dbs.inject(example.method(:run)) do |callback, db|
      Suma::Postgres.logger.debug "DB: Running with an outer transaction"
      proc { db.transaction(auto_savepoint: :only, rollback: :always, &callback) }
    end
    wrapped_proc.call
  end

  singleton_attr_accessor :current_test_model_uid
  self.current_test_model_uid = 0

  module Models; end

  # Create an anonymous model with the given table name.
  # Can be a symbol, string, or [:schema, :table] array.
  module_function def create_model(name, model_class: nil, &block)
    Suma::SpecHelpers::Postgres.current_test_model_uid += 1
    model_class ||= Suma::Postgres::Model
    qualifier = Sequel
    prefix = name
    if name.is_a?(Array)
      qualifier = Sequel[name[0]]
      model_class.create_schema!(qualifier)
      prefix = name[1]
    end
    table_name = "testtable_#{prefix}_#{Suma::SpecHelpers::Postgres.current_test_model_uid}".to_sym
    qualified_name = qualifier[table_name]

    model_class.logger.info "Creating table: %p" % [qualified_name]
    model_class.db.create_table!(qualified_name, &block)
    clsname = table_name.to_s.classify
    clsfqn = "#{Suma::SpecHelpers::Postgres::Models}::#{clsname}"
    cls = Class.new(model_class.Model(qualified_name)) do
      define_singleton_method(:name) { clsfqn }
    end
    Suma::SpecHelpers::Postgres::Models.const_set(clsname, cls)
    return cls
  end

  module_function def truncate_all
    # We can delete items from 'leaf' to 'trunk' in association terms
    # by using the TSort API (so Address and Member, for example, are very early,
    # while 'StripeAttributes', which nothing has an FK into, is very late).
    # This is much faster than truncating with cascade.
    # Though in some cases, it doesn't work, so we need to cascade.
    Suma::Postgres.each_model_superclass do |sc|
      sc.tsort.reverse_each do |m|
        m.dataset.delete
      rescue Sequel::ForeignKeyConstraintViolation
        m.truncate(cascade: true)
      rescue Sequel::DatabaseError
        # The table may not exist, maybe because the type was created in a test
        # and now no longer exists but it still a subclass.
        nil
      end
    end
  end

  # Call the equivalent of `MyModel.where(id: model.id).all.first`
  # so eager loading can be tested.
  module_function def refetch_for_eager(o)
    return o.class.dataset.where(id: o.id).all.first
  end

  #
  # Custom matchers
  #

  RSpec::Matchers.define(:be_saved) do
    match do |model_object|
      !model_object.new?
    end
  end

  class HaveRowMatcher
    include RSpec::Matchers

    def initialize(criteria)
      @criteria = criteria
    end

    def matches?(model)
      @model = model
      @instance = @model[@criteria]
      return false if @instance.nil?

      return @matcher.matches?(@instance) if @matcher

      return true
    end

    def failure_message
      return "Expected %s to have a row matching criteria %p but did not" % [@model.name, @criteria] unless @instance
      return "Row found but matcher failed with: %s" % [@matcher.failure_message] if @matcher
      return "invalid message"
    end

    def failure_message_when_negated
      return "Expected %s to not have a row matching criteria %p but did" % [@model.name, @criteria] if @instance
      return "invalid message"
    end

    def with_attributes(attrs)
      @matcher = RSpec::Matchers::BuiltIn::HaveAttributes.new(attrs)
      return self
    end
  end

  module_function def have_row(criteria)
    return HaveRowMatcher.new(criteria)
  end

  # Matcher that checks that hashes have the same id as objects.
  #
  #   expect( last_response_json_body ).to have_same_ids_as( dataset.all )
  #
  RSpec::Matchers.define(:have_same_ids_as) do |*expected|
    match do |actual|
      @pk ||= :id
      self.ids(actual) == self.ids(expected.flatten)
    end

    failure_message do |actual|
      "expected ids %s to equal ids %s" % [self.ids(actual), self.ids(expected.flatten)]
    end

    chain :ordered do
      @ordered = true
    end

    chain :pk_field do |pk|
      @pk = pk
    end

    def ids(arr)
      res = arr.map { |o| self.id(o) }
      res = res.sort unless @ordered
      return res
    end

    def id(o)
      return o if o.is_a?(Numeric)
      return o.send(@pk) if o.respond_to?(@pk)
      return o[@pk] || o[@pk.to_s]
    end
  end

  RSpec::Matchers.define(:be_destroyed) do
    match do |actual|
      actual.class.where(id: actual.id).empty?
    end

    failure_message do |actual|
      "did not expect to find item with id %s in %s" % [actual.id, actual.class.where(id: actual.id).all]
    end
  end

  RSpec::Matchers.define(:be_bool) do
    match do |actual|
      [true, false].include?(actual)
    end

    failure_message do |actual|
      "%s must be true or false" % [actual]
    end
  end
end
