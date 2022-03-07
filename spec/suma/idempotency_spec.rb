# frozen_string_literal: true

RSpec.describe "Suma::Idempotency", db: :no_transaction do
  let(:described_class) { Suma::Idempotency }

  describe "::every" do
    it "invokes the callback again only after a certain time has elapsed" do
      count = 0
      start = Time.now
      expect do
        Timecop.freeze(start) do
          3.times do
            described_class.every(12.hours).under_key("some-key") { count += 1 }
            Timecop.travel(1.hours)
            described_class.every(12.hours).under_key("some-key") { count += 1 }
            Timecop.travel(13.hours)
          end
        end
      end.to change { count }.by(3)
    end
  end

  describe "::once_ever" do
    it "only invokes the callback the first time" do
      count = 0
      expect do
        3.times do
          described_class.once_ever.under_key("some-key") { count += 1 }
        end
      end.to change { count }.by(1)
    end
  end

  describe "every and once_ever" do
    it "returns the block result if the callback executes, NOOP if not" do
      expect(described_class.once_ever.under_key("some-key") { 5 }).to eq(5)
      expect(described_class.once_ever.under_key("some-key") { 5 }).to eq(described_class::NOOP)
    end

    it "raises if inside of a transaction" do
      described_class.db.transaction do
        expect do
          described_class.once_ever.under_key("some-key") { 5 }
        end.to raise_error(Suma::Postgres::InTransaction)
      end
    end
  end

  describe "transaction_ok" do
    it "allows a transaction" do
      described_class.db.transaction do
        expect do
          described_class.once_ever.under_key("some-key") { 5 }
        end.to raise_error(Suma::Postgres::InTransaction)

        expect do
          described_class.once_ever.under_key("some-key").transaction_ok { 5 }
        end.to_not raise_error
      end
    end
  end
end
