# frozen_string_literal: true

require "suma/api/webhookdb"

RSpec.describe Suma::API::Webhookdb, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }

  describe "POST /v1/webhookdb/stripe_refund_v1" do
    it "enqueues the async jobs", sidekiq: :fake do
      header "Whdb-Webhook-Secret", Suma::Webhookdb.stripe_refunds_secret

      post "/v1/webhookdb/stripe_refund_v1", {x: 1}

      expect(last_response).to have_status(202)
      expect(Suma::Async::StripeRefundsBackfiller.jobs).to have_length(1)
    end

    it "errors if the webhook header does not match" do
      post "/v1/webhookdb/stripe_refund_v1", {x: 1}

      expect(last_response).to have_status(401)
    end
  end

  describe "POST /v1/webhookdb/signalwire_message_v1" do
    it "enqueues the async jobs", sidekiq: :fake do
      header "Whdb-Webhook-Secret", Suma::Webhookdb.signalwire_messages_secret

      post "/v1/webhookdb/signalwire_message_v1", {x: 1}

      expect(last_response).to have_status(202)
      expect(Suma::Async::SignalwireProcessOptouts.jobs).to have_length(1)
    end

    it "errors if the webhook header does not match" do
      post "/v1/webhookdb/signalwire_message_v1", {x: 1}

      expect(last_response).to have_status(401)
    end
  end
end
