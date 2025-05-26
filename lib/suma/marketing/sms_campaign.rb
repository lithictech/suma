# frozen_string_literal: true

require "suma/marketing"
require "suma/postgres/model"
require "suma/async/marketing_sms_campaign_dispatch"

class Suma::Marketing::SmsCampaign < Suma::Postgres::Model(:marketing_sms_campaigns)
  plugin :timestamps

  plugin :translated_text, :body, Suma::TranslatedText

  many_to_one :created_by, class: "Suma::Member"

  many_to_many :lists,
               class: "Suma::Marketing::List",
               join_table: :marketing_lists_campaigns,
               left_key: :list_id,
               right_key: :campaign_id

  one_to_many :sms_dispatches, class: "Suma::Marketing::SmsDispatch"

  # Create +Suma::Marketing::SmsDispatch+ instances for each member in +lists+.
  # Enqueue the background job that sends the actual messages.
  def dispatch(*lists)
    members = lists.map(&:members).flatten.uniq
    rows = members.map { |m| {member_id: m.id, sms_campaign_id: self.id} }
    Suma::Marketing::SmsDispatch.dataset.insert_conflict.multi_insert(rows)
    Suma::Async::MarketingSmsCampaignDispatch.perform_async
    self.associations.delete(:sms_dispatches)
    return members
  end

  # Call +render+ for each supported language.
  def preview(member)
    en = self.render(member:, language: :en)
    es = self.render(member:, language: :es)
    return {en:, es:}
  end

  # Render the campaign template in the given language.
  # If +language+ is nil, use the member's message preferences.
  def render(member:, language:)
    language ||= member.message_preferences!.preferred_language
    ctx = {name: member&.name, phone: member&.us_phone, email: member&.email}
    ctx.stringify_keys!
    content = self.body.send(language)
    tmpl = Liquid::Template.parse(content)
    r = tmpl.render(ctx)
    return r
  end
end
