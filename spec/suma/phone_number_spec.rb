# frozen_string_literal: true

RSpec.describe Suma::PhoneNumber do
  describe Suma::PhoneNumber::US do
    it "can format a normalized number as US" do
      expect(described_class.format("13334445555")).to eq("(333) 444-5555")
      expect(described_class.format?("13334445555")).to eq("(333) 444-5555")
    end

    it "errors if the number is not normalized" do
      expect { described_class.format("3334445555") }.to raise_error(Suma::PhoneNumber::BadFormat)
      expect(described_class.format?("3334445555")).to be_nil
    end
  end

  describe "format_e164" do
    it "returns a phone number in E.164 format with a US country code" do
      expect(described_class.format_e164("5554443210")).to eq("+15554443210")
    end

    it "strips non-numeric characters if present" do
      expect(described_class.format_e164("(555) 444-3210")).to eq("+15554443210")
    end

    it "handles a country code already being present" do
      expect(described_class.format_e164("+1 (555) 444-3210")).to eq("+15554443210")
    end

    it "does not modify a properly formatted US number" do
      expect(described_class.format_e164("+15554443210")).to eq("+15554443210")
    end

    it "errors if number is not valid" do
      expect { described_class.format_e164("555444321") }.to raise_error(described_class::BadFormat)
      expect { described_class.format_e164("notaphonenumber") }.to raise_error(described_class::BadFormat)
      expect { described_class.format_e164("") }.to raise_error(described_class::BadFormat)
      expect { described_class.format_e164(nil) }.to raise_error(described_class::BadFormat)

      expect(described_class.format_e164?("555444321")).to be_nil
    end
  end

  describe "format_display" do
    it "uses the format appropriate to the number, falling back to unformatted" do
      expect(described_class.format_display("13334445555")).to eq("(333) 444-5555")
      expect(described_class.format_display("3334445555")).to eq("3334445555")
    end
  end

  describe "unformat_e164" do
    it "returns the leading + sign stripped" do
      expect(described_class.unformat_e164("+1555444321")).to eq("1555444321")
    end

    it "raises if not in e164 format" do
      expect { described_class.unformat_e164("1555444321") }.to raise_error(described_class::BadFormat)
      expect { described_class.unformat_e164("+15554 44321") }.to raise_error(described_class::BadFormat)
      expect(described_class.unformat_e164?("+15554 44321")).to be_nil
    end
  end
end
