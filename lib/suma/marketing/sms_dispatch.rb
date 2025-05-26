# frozen_string_literal: true

require "suma/marketing"
require "suma/postgres/model"

class Suma::Marketing::SmsDispatch < Suma::Postgres::Model(:marketing_sms_dispatches)
  plugin :timestamps

  many_to_one :member, class: "Suma::Member"
  many_to_one :sms_campaign, class: "Suma::Marketing::SmsCampaign"

  dataset_module do
    def pending = self.where(sent_at: nil)
  end

  class << self
    def send_all
      return if Suma::Signalwire.marketing_number.blank?
      Suma::Postgres.check_transaction(
        self.db,
        "cannot send sms while in a transaction due to potential progress loss",
      )
      marketing_number = Suma::PhoneNumber.format_e164(Suma::Signalwire.marketing_number)
      self.dataset.pending.each do |dispatch|
        body = dispatch.sms_campaign.render(member: dispatch.member, language: nil)
        begin
          sw_resp = Suma::Signalwire.send_sms(
            marketing_number,
            Suma::PhoneNumber.format_e164(dispatch.member.phone),
            body,
          )
        rescue Twilio::REST::RestError => e
          tags = {
            member_id: dispatch.member.id,
            member_name: dispatch.member.name,
            campaign_id: dispatch.sms_campaign.id,
            campaign: dispatch.sms_campaign.name,
          }
          self.logger.error("dispatch_marketing_campaign_error", tags, e)
          Sentry.capture_exception(e, tags:)
          next
        end
        self.logger.info(
          "dispatched_marketing_campaign",
          member_id: dispatch.member.id,
          campaign: dispatch.sms_campaign.name,
          signalwire_message_id: sw_resp.sid,
        )
        dispatch.sent = Time.now
        dispatch.save_changes
      end
    end
  end

  def sent? = Suma::MethodUtilities.timestamp_set?(self, :sent_at)

  def sent=(v)
    Suma::MethodUtilities.timestamp_set(self, :sent_at, v)
  end
end
