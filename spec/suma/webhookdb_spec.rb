# frozen_string_literal: true

require "suma/webhookdb"

RSpec.describe Suma::Webhookdb, reset_configuration: Suma::Webhookdb do
  describe "models" do
    it "can be disabled, in which case a mock connection is used" do
      expect(Suma::Webhookdb.models_enabled).to be(true)
      expect(Suma::Webhookdb::Model.db["SELECT 1 AS one"].first).to eq({one: 1})
      Suma::Webhookdb.models_enabled = false
      # this is a mock dataset now
      expect(Suma::Webhookdb::Model.db["SELECT 1 AS one"].first).to eq(nil)
    end
  end
end
