# frozen_string_literal: true

require "suma/i18n"

RSpec.describe Suma::I18n, :db do
  describe "localized_error_codes" do
    it "returns errors as listed in the strings seed file" do
      expect(described_class.localized_error_codes).to include("auth_conflict")
    end
  end

  describe "flatten_hash" do
    nested_hash = {
      "x" => 1,
      "y" => {
        "b" => 1,
        "a" => 2,
      },
      "h" => 3,
    }

    it "flattens a hash" do
      h = nested_hash.deep_dup
      expect(described_class.flatten_hash(nested_hash)).to eq({"h" => 3, "x" => 1, "y.a" => 2, "y.b" => 1})
      # Assert original unchanged
      expect(nested_hash).to eq(h)
    end
  end
end
