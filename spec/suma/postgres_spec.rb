# frozen_string_literal: true

require "suma/postgres"

RSpec.describe Suma::Postgres do
  # Since this spec tests model registration, save them before the tests run,
  # ensure that they're cleared before every test, then restore them after
  before(:all) do
    @original_superclasses = described_class.model_superclasses.dup
    @original_models = described_class.registered_models.dup
  end

  after(:all) do
    described_class.registered_models.replace(@original_models)
    described_class.model_superclasses.replace(@original_superclasses)
  end

  before(:each) do
    described_class.model_superclasses.clear
    described_class.registered_models.clear
  end

  it "provides a place for model superclasses to register themselves" do
    superclass = Class.new
    described_class.register_model_superclass(superclass)
    expect(described_class.model_superclasses).to include(superclass)
  end

  it "requires registered models immediately if any model superclass has a connection" do
    conn = double("dummy connection")
    superclass = double("model superclass", db: conn)
    described_class.model_superclasses.add(superclass)

    expect(described_class).to receive(:require).with("spacemonkeys")
    described_class.register_model("spacemonkeys")

    expect(described_class.registered_models).to include("spacemonkeys")
  end

  it "defers requiring registered models if there are no model superclasses" do
    expect(described_class).to_not receive(:require)
    described_class.register_model("spacemonkeys")
    expect(described_class.registered_models).to include("spacemonkeys")
  end

  it "defers requiring registered models if no model superclass has a connection" do
    superclass = double("model superclass", db: nil)
    described_class.model_superclasses.add(superclass)

    expect(described_class).to_not receive(:require)
    described_class.register_model("spacemonkeys")

    expect(described_class.registered_models).to include("spacemonkeys")
  end

  it "can iterate classes" do
    described_class.registered_models.replace(@original_models)
    described_class.model_superclasses.replace(@original_superclasses)

    sup = described_class.each_model_superclass.to_a
    expect(sup).to include(described_class::Model)

    models = []
    described_class.each_model_class { |c| models << c }
    expect(models).to include(Suma::Member)
  end

  describe "now_sql" do
    it "uses Ruby now" do
      t1 = Timecop.travel("2020-01-30T12:00:00Z") do
        described_class::Model.db[described_class.now_sql].sql
      end
      t2 = Timecop.travel("2020-02-15T12:00:00Z") do
        described_class::Model.db[described_class.now_sql].sql
      end
      expect(t1).to start_with("SELECT * FROM CAST('2020-01-30")
      expect(t2).to start_with("SELECT * FROM CAST('2020-02-15")
    end
  end
end
