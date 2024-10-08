# frozen_string_literal: true

require "suma/postgres/model_utilities"

RSpec.describe Suma::Postgres::ModelUtilities do
  before(:all) do
    @real_superclasses = Suma::Postgres.model_superclasses.dup
    @real_models = Suma::Postgres.registered_models.dup
  end

  before(:each) do
    Suma::Postgres.model_superclasses.clear
    Suma::Postgres.registered_models.clear
  end

  after(:all) do
    Suma::Postgres.model_superclasses.replace(@real_superclasses)
    Suma::Postgres.registered_models.replace(@real_models)
  end

  let(:extended_class) do
    model_class = Class.new(Sequel::Model)
    model_class.extend(Appydays::Loggable)
    model_class.extend(described_class)
    model_class.db = Sequel.connect("mock://postgres")
    model_class
  end

  RSpec::Matchers.define :be_included_in do |expected|
    match do |actual|
      expected.include?(actual)
    end
  end

  it "is registered as a model superclass" do
    expect(extended_class).to be_included_in(Suma::Postgres.model_superclasses)
  end

  it "has a method to set the application name associated with the db" do
    expect(extended_class.db).to receive(:synchronize) do |&block|
      conn = instance_double(PG::Connection)
      expect(conn).to receive(:escape_string) do |string|
        string
      end
      expect(conn).to receive(:exec).
        with("SET application_name TO 'Suma::Postgres::ModelUtilities Spec'")

      block.call(conn)
    end

    extended_class.appname = "Suma::Postgres::ModelUtilities Spec"
  end
end
