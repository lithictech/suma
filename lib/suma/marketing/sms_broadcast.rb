# frozen_string_literal: true

require "smstools"

require "suma/marketing"
require "suma/postgres/model"
require "suma/async/marketing_sms_broadcast_dispatch"

class Suma::Marketing::SmsBroadcast < Suma::Postgres::Model(:marketing_sms_broadcasts)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked

  plugin :association_pks
  plugin :hybrid_search
  plugin :timestamps
  plugin :translated_text, :body, Suma::TranslatedText

  many_to_one :created_by, class: "Suma::Member"

  many_to_many :lists,
               class: "Suma::Marketing::List",
               join_table: :marketing_lists_sms_broadcasts,
               order: :list_id
  plugin :association_array_replacer, :lists

  one_to_many :sms_dispatches, class: "Suma::Marketing::SmsDispatch", order: order_desc

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
        en_payload: Payload.parse(en),
        es:,
        es_payload: Payload.parse(es),
      }
    end
  end

  def sent? = Suma::MethodUtilities.timestamp_set?(self, :sent_at)

  def sent=(v)
    Suma::MethodUtilities.timestamp_set(self, :sent_at, v)
  end

  # Create +Suma::Marketing::SmsDispatch+ instances for each member in +lists+.
  # Enqueue the background job that sends the actual messages.
  # If the broadcast is already sent (and +force+ is false), ONLY enqueue the background job.
  # This prevents any accidental additional dispatches as lists change.
  def dispatch(force: false)
    if !force && self.sent?
      Suma::Async::MarketingSmsBroadcastDispatch.perform_async
      return []
    end
    members = self.lists.map(&:members).flatten.uniq
    rows = members.map { |m| {member_id: m.id, sms_broadcast_id: self.id} }
    Suma::Marketing::SmsDispatch.dataset.insert_conflict.multi_insert(rows)
    self.sent = true
    self.save_changes
    self.associations.delete(:sms_dispatches)
    Suma::Async::MarketingSmsBroadcastDispatch.perform_async
    return members
  end

  # Call +render+ for each supported language.
  def preview(member)
    return self.class.preview(member:, en: self.body.en, es: self.body.es)
  end

  # Render the broadcast template in the given language.
  # If +language+ is nil, use the member's message preferences.
  def render(member:, language:)
    language ||= member.message_preferences!.preferred_language
    content = self.body.send(language)
    return self.class.render(member:, content:)
  end

  # Return the +PreReview+ or +PostReview+ for this broadcast.
  # It calculates all the SMS being sent for the members on the lists,
  # in their preferred language.
  def generate_review
    return self.sent? ? self.generate_post_review : self.generate_pre_review
  end

  def generate_pre_review
    members = self.lists.map(&:members).flatten.uniq
    result = PreReview.new(
      broadcast: self,
      list_labels: self.lists.map { |li| "#{li.label} (#{li.members.count})" }.sort,
    )
    members.each do |member|
      language = member.message_preferences!.preferred_language
      member_text = self.render(member:, language:)
      next if member_text.blank?
      cost = Payload.parse(member_text).cost
      result.total_recipients += 1
      result.total_cost += cost
      if language == "en"
        result.en_recipients += 1
        result.en_total_cost += cost
      else
        result.es_recipients += 1
        result.es_total_cost += cost
      end
    end
    return result
  end

  def generate_post_review
    msg_ds = Suma::Webhookdb.signalwire_messages_dataset
    msg_ds = msg_ds.where(signalwire_id: self.sms_dispatches.map(&:transport_message_id))
    sw_payloads = msg_ds.select_map(:data)
    delivered_status = ["sent", "delivered"]
    failed_status = ["failed", "undelivered"]
    delivered_recipients = sw_payloads.count { |d| delivered_status.include?(d.fetch("status")) }
    failed_recipients = sw_payloads.count { |d| failed_status.include?(d.fetch("status")) }
    canceled_recipients = self.sms_dispatches.count(&:canceled?)
    result = PostReview.new(
      broadcast: self,
      total_recipients: self.sms_dispatches.count,
      list_labels: self.lists.map(&:label).sort,
      delivered_recipients:,
      failed_recipients:,
      canceled_recipients:,
      pending_recipients: self.sms_dispatches.count - delivered_recipients - failed_recipients - canceled_recipients,
      actual_cost: sw_payloads.sum(BigDecimal(0)) { |d| d.fetch("price", 0) },
    )
    return result
  end

  def rel_admin_link = "/marketing-sms-broadcast/#{self.id}"

  def hybrid_search_fields
    return [
      :label,
      :sent_at,
    ]
  end

  class Payload < Suma::TypedStruct
    attr_reader :characters, :segments, :cost

    def self.parse(s)
      ed = SmsTools::EncodingDetection.new(s)
      return self.new(
        characters: ed.length,
        segments: ed.concatenated_parts,
        cost: ed.concatenated_parts * Suma::Signalwire::SMS_COST_PER_SEGMENT,
      )
    end
  end

  class PreReview < Suma::TypedStruct
    attr_accessor :broadcast,
                  :list_labels,
                  :total_recipients,
                  :en_recipients,
                  :es_recipients,
                  :total_cost,
                  :en_total_cost,
                  :es_total_cost

    def pre_review? = true

    def _defaults
      return {
        list_labels: [],
        total_recipients: 0,
        en_recipients: 0,
        es_recipients: 0,
        total_cost: BigDecimal(0),
        en_total_cost: BigDecimal(0),
        es_total_cost: BigDecimal(0),
      }
    end
  end

  class PostReview < Suma::TypedStruct
    attr_reader :broadcast,
                :list_labels,
                :total_recipients,
                :delivered_recipients,
                :failed_recipients,
                :canceled_recipients,
                :pending_recipients,
                :actual_cost

    def pre_review? = false
  end
end

# Table: marketing_sms_broadcasts
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id               | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at       | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at       | timestamp with time zone |
#  sent_at          | timestamp with time zone |
#  label            | text                     | NOT NULL
#  body_id          | integer                  | NOT NULL
#  created_by_id    | integer                  |
#  search_content   | text                     |
#  search_embedding | vector(384)              |
#  search_hash      | text                     |
# Indexes:
#  marketing_sms_broadcasts_pkey                          | PRIMARY KEY btree (id)
#  marketing_sms_broadcasts_search_content_tsvector_index | gin (to_tsvector('english'::regconfig, search_content))
# Foreign key constraints:
#  marketing_sms_broadcasts_body_id_fkey       | (body_id) REFERENCES translated_texts(id)
#  marketing_sms_broadcasts_created_by_id_fkey | (created_by_id) REFERENCES members(id) ON DELETE SET NULL
# Referenced By:
#  marketing_lists_sms_broadcasts | marketing_lists_sms_broadcasts_sms_broadcast_id_fkey | (sms_broadcast_id) REFERENCES marketing_sms_broadcasts(id) ON DELETE CASCADE
#  marketing_sms_dispatches       | marketing_sms_dispatches_sms_broadcast_id_fkey       | (sms_broadcast_id) REFERENCES marketing_sms_broadcasts(id)
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
