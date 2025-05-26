# frozen_string_literal: true

require "smstools"

require "suma/marketing"
require "suma/postgres/model"
require "suma/async/marketing_sms_campaign_dispatch"

class Suma::Marketing::SmsCampaign < Suma::Postgres::Model(:marketing_sms_campaigns)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked

  plugin :association_pks
  plugin :hybrid_search
  plugin :timestamps
  plugin :translated_text, :body, Suma::TranslatedText

  many_to_one :created_by, class: "Suma::Member"

  many_to_many :lists,
               class: "Suma::Marketing::List",
               join_table: :marketing_lists_sms_campaigns,
               left_key: :sms_campaign_id,
               right_key: :list_id
  plugin :association_array_replacer, :lists

  one_to_many :sms_dispatches, class: "Suma::Marketing::SmsDispatch"

  class << self
    def render(member:, content:)
      ctx = {name: member&.name, phone: member&.us_phone, email: member&.email}
      ctx.stringify_keys!
      begin
        tmpl = Liquid::Template.parse(content)
      rescue Liquid::SyntaxError
        return content
      end
      r = tmpl.render(ctx)
      return r
    end

    def preview(member:, en:, es:)
      en = self.render(member:, content: en)
      es = self.render(member:, content: es)
      return {
        en:,
        en_payload: self.inspect_payload(en),
        es:,
        es_payload: self.inspect_payload(es),
      }
    end

    def inspect_payload(s)
      ed = SmsTools::EncodingDetection.new s
      return {
        characters: ed.length,
        segments: ed.concatenated_parts,
        cost: ed.concatenated_parts * Suma::Signalwire::SMS_COST_PER_SEGMENT,
      }
    end
  end

  def sent? = Suma::MethodUtilities.timestamp_set?(self, :sent_at)

  def sent=(v)
    Suma::MethodUtilities.timestamp_set(self, :sent_at, v)
  end

  # Create +Suma::Marketing::SmsDispatch+ instances for each member in +lists+.
  # Enqueue the background job that sends the actual messages.
  def dispatch
    members = self.lists.map(&:members).flatten.uniq
    rows = members.map { |m| {member_id: m.id, sms_campaign_id: self.id} }
    Suma::Marketing::SmsDispatch.dataset.insert_conflict.multi_insert(rows)
    Suma::Async::MarketingSmsCampaignDispatch.perform_async
    self.associations.delete(:sms_dispatches)
    self.sent = true
    self.save_changes
    return members
  end

  # Call +render+ for each supported language.
  def preview(member)
    return self.class.preview(member:, en: self.body.en, es: self.body.es)
  end

  # Render the campaign template in the given language.
  # If +language+ is nil, use the member's message preferences.
  def render(member:, language:)
    language ||= member.message_preferences!.preferred_language
    content = self.body.send(language)
    return self.class.render(member:, content:)
  end

  def rel_admin_link = "/marketing-sms-campaign/#{self.id}"

  def hybrid_search_fields
    return [
      :label,
      :sent_at,
    ]
  end
end
