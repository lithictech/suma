# frozen_string_literal: true

require "suma/payment/reviewer"

RSpec.describe Suma::Payment::Reviewer, :db do
  describe "act" do
    describe "with a funding transaction" do
      let(:strategy) { Suma::Payment::FakeStrategy.create }
      let(:payment) { Suma::Fixtures.funding_transaction.with_fake_strategy(strategy).create }
      let(:member) { payment.originating_payment_account.member }

      before(:each) do
        expect(payment).to transition_on(:put_into_review).with("mymessage", "hi").to("needs_review")
        payment.save_changes
      end

      it "cancels the payment", :i18n do
        r = described_class.new(payment)
        r.act
        expect(Suma::Support::Ticket.all).to be_empty
        expect(payment.refresh).to have_attributes(status: "canceled")
      end

      it "creates a ticket if the cancel fails" do
        expect(payment).to receive(:cancel).and_return(false)
        r = described_class.new(payment)
        r.act
        pk = payment.pk
        expect(Suma::Support::Ticket.all).to contain_exactly(
          have_attributes(
            body: "FundingTransaction #{pk} was put into review.\n" \
                  "Admin link: http://localhost:22014/funding-transaction/#{pk}\n" \
                  "Reason: hi\n" \
                  "Message: mymessage",
          ),
        )
      end
    end
  end

  describe "act" do
    describe "with a payout transaction" do
      let(:strategy) { Suma::Payment::FakeStrategy.create }
      let(:payment) { Suma::Fixtures.payout_transaction.with_fake_strategy(strategy).create }
      let(:member) { payment.originating_payment_account.member }

      before(:each) do
        expect(payment).to transition_on(:put_into_review).with("mymessage", "hi").to("needs_review")
        payment.save_changes
      end

      it "creates a ticket" do
        r = described_class.new(payment)
        r.act
        pk = payment.pk
        expect(Suma::Support::Ticket.all).to contain_exactly(
          have_attributes(
            body: "PayoutTransaction #{pk} was put into review.\n" \
                  "Admin link: http://localhost:22014/payout-transaction/#{pk}\n" \
                  "Reason: hi\n" \
                  "Message: mymessage",
          ),
        )
      end
    end
  end
end
