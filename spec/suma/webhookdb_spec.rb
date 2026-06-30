# frozen_string_literal: true

require "suma/webhookdb"

RSpec.describe Suma::Webhookdb do
  describe "models" do
    it "can be disabled, in which case a mock connection is used" do
      Suma::Webhookdb.models_enabled = true
      expect(Suma::Webhookdb::Model.db["SELECT 1 AS one"].first).to eq({one: 1})
      Suma::Webhookdb.models_enabled = false
      # this is a mock dataset now
      expect(Suma::Webhookdb::Model.db["SELECT 1 AS one"].first).to eq(nil)
    ensure
      # Don't use reset_configuration, it opens a new connection and can cause problems in other tests.
      Suma::Webhookdb.models_enabled = true
    end
  end

  describe "RowIterator", :db do
    let(:ds) { described_class.stripe_charges_dataset }
    let(:iterator) do
      iter = described_class::RowIterator.new("test-rowiterator")
      iter.reset
      iter
    end

    it "iterates through unprocessed rows" do
      ds.insert(stripe_id: "x1", data: "{}")
      ds.insert(stripe_id: "x2", data: "{}")
      arr = []
      iterator.each(ds) { |r| arr << r[:stripe_id] }
      expect(arr).to eq(["x1", "x2"])
      iterator.each(ds) { |r| arr << r[:stripe_id] }
      expect(arr).to eq(["x1", "x2"])
      ds.insert(stripe_id: "x3", data: "{}")
      iterator.each(ds) { |r| arr << r[:stripe_id] }
      expect(arr).to eq(["x1", "x2", "x3"])
    end

    it "iterates through pages" do
      ds.insert(stripe_id: "x1", data: "{}")
      ds.insert(stripe_id: "x2", data: "{}")
      arr = []
      iterator.each_page(ds) { |page| page.each { |r| arr << r[:stripe_id] } }
      expect(arr).to eq(["x1", "x2"])
      iterator.each_page(ds) { |page| page.each { |r| arr << r[:stripe_id] } }
      expect(arr).to eq(["x1", "x2"])
      ds.insert(stripe_id: "x3", data: "{}")
      iterator.each_page(ds) { |page| page.each { |r| arr << r[:stripe_id] } }
      expect(arr).to eq(["x1", "x2", "x3"])
    end
  end
end
