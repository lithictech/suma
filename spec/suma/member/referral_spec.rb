# frozen_string_literal: true

RSpec.describe "Suma::Member::Referral", :db do
  let(:described_class) { Suma::Member::Referral }

  describe "from_params" do
    it "returns an unsaved referral if there are any relevant cookies" do
      r = described_class.from_params({utm_source: "foo", "utm_campaign" => "bar", utm_medium: "baz"})
      expect(r).to have_attributes(source: "foo", campaign: "bar", medium: "baz")
    end

    it "returns nil if there are no relevant cookies" do
      r = described_class.from_params({})
      expect(r).to be_nil
      r = described_class.from_params({utm_source: nil})
      expect(r).to be_nil
    end

    it "provides an unknown source if utm_source is not present" do
      r = described_class.from_params({utm_campaign: "bar"})
      expect(r).to have_attributes(source: "", campaign: "bar")
    end
  end
end
