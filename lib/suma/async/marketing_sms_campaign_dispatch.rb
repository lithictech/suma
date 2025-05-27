# frozen_string_literal: true

require "amigo/job"
require "suma/async"

class Suma::Async::MarketingSmsCampaignDispatch
  extend Amigo::Job

  def _perform(_event)
    Suma::Marketing::SmsDispatch.send_all
  end
end
