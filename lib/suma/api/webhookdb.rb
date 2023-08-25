# frozen_string_literal: true

require "suma/api"

require "suma/async/stripe_refunds_backfiller"

class Suma::API::Webhookdb < Suma::API::V1
  include Suma::API::Entities

  resource :webhookdb do
    post :stripe_refund_v1 do
      h = env["HTTP_WHDB_WEBHOOK_SECRET"]
      unauthenticated! unless h == Suma::Webhookdb.stripe_refunds_secret
      Suma::Async::StripeRefundsBackfiller.perform_async
      status 202
      present({o: "k"})
    end
  end
end
