# frozen_string_literal: true

require "suma/payment"

RSpec.describe Suma::Payment, :db do
  describe "ensure_cash_ledger" do
    let(:member) { Suma::Fixtures.member.create }
    it "creates a payment account and cash ledger" do
      led = described_class.ensure_cash_ledger(member)
      expect(led.vendor_service_categories).to contain_exactly(have_attributes(name: "Cash"))
      expect(led).to be === member.payment_account.cash_ledger
      expect(led).to have_attributes(name: "Cash")
    end

    it "can reuse an existing cash ledger" do
      led1 = described_class.ensure_cash_ledger(member)
      member.refresh
      led2 = described_class.ensure_cash_ledger(member)
      expect(led2).to be === led1
      expect(led1).to be === member.payment_account.cash_ledger
    end
  end

  describe Suma::Payment::Institution do
    describe "logo_to_src" do
      it "converts nil to empty string" do
        expect(described_class.logo_to_src(nil)).to eq("")
      end
      it "ignores empty string" do
        expect(described_class.logo_to_src("")).to eq("")
      end
      it "does not modify urls with a protocol" do
        expect(described_class.logo_to_src("https://foo")).to eq("https://foo")
        expect(described_class.logo_to_src("data:foo")).to eq("data:foo")
        expect(described_class.logo_to_src("data://foo")).to eq("data://foo")
        expect(described_class.logo_to_src("data:image/png;base64,iii")).to eq("data:image/png;base64,iii")
      end
      it "handles pngs" do
        expect(described_class.logo_to_src("iVBORw0KGgoAAAANSUhEUgAABLAAAAS")).to eq(
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAABLAAAAS",
        )
        b = Base64.strict_encode64(File.binread(Suma::SpecHelpers::TEST_DATA_DIR + "images/photo.png"))
        expect(described_class.logo_to_src(b)).to start_with(
          "data:image/png;base64,iVBORw0KGgo",
        )
      end
      it "uses mimemagic to detect non-png" do
        b = Base64.strict_encode64(File.binread(Suma::SpecHelpers::TEST_DATA_DIR + "images/turkey-dinner.jpeg"))
        expect(described_class.logo_to_src(b)).to start_with(
          "data:image/jpeg;base64,/9j/4AAQSkZJRgAB",
        )
      end
      it "does not modify garbage" do
        not_b64 = "zz38&320"
        expect(described_class.logo_to_src(not_b64)).to eq(not_b64)
        not_content = Base64.strict_encode64("foo")
        expect(described_class.logo_to_src(not_content)).to eq(not_content)
      end
    end
  end
end
