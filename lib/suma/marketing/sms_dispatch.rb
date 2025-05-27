# frozen_string_literal: true

require "suma/external_links"
require "suma/marketing"
require "suma/postgres/model"

class Suma::Marketing::SmsDispatch < Suma::Postgres::Model(:marketing_sms_dispatches)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked
  include Suma::ExternalLinks

  plugin :hybrid_search
  plugin :timestamps

  many_to_one :member, class: "Suma::Member"
  many_to_one :sms_campaign, class: "Suma::Marketing::SmsCampaign"

  dataset_module do
    def pending = self.where(sent_at: nil)
  end

  class << self
    def send_all
      Suma::Postgres.check_transaction(
        self.db,
        "cannot send sms while in a transaction due to potential progress loss",
      )
      if Suma::Signalwire.marketing_number.blank?
        self.logger.info("sms_dispatch_no_marketing_number")
        self.dataset.pending.each do |dispatch|
          dispatch.cancel
          dispatch.save_changes
        end
        return
      end
      marketing_number = Suma::PhoneNumber.format_e164(Suma::Signalwire.marketing_number)
      self.dataset.pending.each do |dispatch|
        body = dispatch.sms_campaign.render(member: dispatch.member, language: nil)
        if body.blank?
          dispatch.cancel.save_changes
          next
        end
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
            campaign: dispatch.sms_campaign.label,
          }
          self.logger.error("dispatch_marketing_campaign_error", tags, e)
          Sentry.capture_exception(e, tags:)
          next
        end
        self.logger.info(
          "dispatched_marketing_campaign",
          member_id: dispatch.member.id,
          campaign: dispatch.sms_campaign.label,
          signalwire_message_id: sw_resp.sid,
        )
        dispatch.set_sent(sw_resp.sid)
        dispatch.save_changes
      end
    end
  end

  def status
    return :canceled if self.sent_at && self.transport_message_id == ""
    return :sent if self.sent_at
    return :pending
  end

  def sent? = self.status == :sent
  def pending? = self.status == :pending
  def canceled? = self.status == :canceled
  def can_cancel? = self.status == :pending

  def set_sent(transport_message_id, at: Time.now)
    raise ArgumentError, "transport_message_id must be present" if transport_message_id.blank?
    self.sent_at = at
    self.transport_message_id = transport_message_id
    self.last_error = nil
    return self
  end

  def cancel(at: Time.now)
    self.sent_at = at
    self.transport_message_id = ""
    return self
  end

  def rel_admin_link = "/marketing-sms-dispatch/#{self.id}"

  def hybrid_search_fields
    return [
      :member,
      :sms_campaign,
      :sent_at,
      :transport_message_id,
      :last_error,
      :status,
    ]
  end

  def _external_links_self
    return [] if self.transport_message_id.blank?
    return [
      self._external_link(
        "Signalwire Message",
        "https://#{Suma::Signalwire.space_url}/logs/messages/#{self.transport_message_id}",
      ),
    ]
  end
end
