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
end
