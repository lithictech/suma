# frozen_string_literal: true

require "suma/admin_linked"
require "suma/postgres/hybrid_search"
require "suma/postgres/model"
require "suma/sse"
require "suma/state_machine"

class Suma::Organization::Membership::Verification < Suma::Postgres::Model(:organization_membership_verifications)
  include Appydays::Configurable
  include Suma::AdminLinked
  include Suma::Postgres::HybridSearch

  configurable(:verifications) do
    setting :front_partner_channel_id, ""
    setting :front_member_channel_id, ""
    setting :front_partner_default_template_id, ""
    setting :front_member_default_en_template_id, ""
    setting :front_member_default_es_template_id, ""

    after_configured do
      self.front_partner_channel_id = Suma::Frontapp.to_channel_id(front_partner_channel_id)
      self.front_member_channel_id = Suma::Frontapp.to_channel_id(front_member_channel_id)
      self.front_partner_default_template_id = Suma::Frontapp.to_template_id(front_partner_default_template_id)
      self.front_member_default_en_template_id = Suma::Frontapp.to_template_id(front_member_default_en_template_id)
      self.front_member_default_es_template_id = Suma::Frontapp.to_template_id(front_member_default_es_template_id)
    end
  end

  plugin :hybrid_search
  plugin :state_machine
  plugin :timestamps
  plugin :column_encryption do |enc|
    enc.column :account_number, searchable: :case_insensitive
  end

  many_to_one :membership, class: "Suma::Organization::Membership"
  one_to_many :audit_logs,
              class: "Suma::Organization::Membership::Verification::AuditLog",
              order: order_desc(:at),
              key: :verification_id
  many_to_many :notes,
               class: "Suma::Support::Note",
               join_table: :support_notes_organization_membership_verifications,
               left_key: :verification_id,
               order: order_desc
  many_to_one :owner, class: "Suma::Member"

  many_to_one :front_partner_conversation,
              class: "Suma::Webhookdb::FrontConversation",
              read_only: true,
              key: :partner_outreach_front_conversation_id,
              primary_key: :front_id
  many_to_one :front_member_conversation,
              class: "Suma::Webhookdb::FrontConversation",
              read_only: true,
              key: :member_outreach_front_conversation_id,
              primary_key: :front_id
  many_to_one :front_latest_partner_message,
              class: "Suma::Webhookdb::FrontMessage",
              read_only: true,
              key: :partner_outreach_front_conversation_id,
              primary_key: :front_conversation_id,
              instance_specific: false do |ds|
    ds.distinct(:front_conversation_id).order(:front_conversation_id, Sequel.desc(:created_at))
  end
  many_to_one :front_latest_member_message,
              class: "Suma::Webhookdb::FrontMessage",
              read_only: true,
              key: :member_outreach_front_conversation_id,
              primary_key: :front_conversation_id,
              instance_specific: false do |ds|
    ds.distinct(:front_conversation_id).order(:front_conversation_id, Sequel.desc(:created_at))
  end

  state_machine :status, initial: :created do
    state :created,
          :in_progress,
          :verified,
          :ineligible,
          :abandoned

    event :start do
      transition created: :in_progress
    end
    after_transition on: :start, do: :start!

    event :abandon do
      transition in_progress: :abandoned
    end
    event :resume do
      transition abandoned: :in_progress
    end
    event :reject do
      transition in_progress: :ineligible
    end
    event :approve do
      transition in_progress: :verified, if: :can_approve?
    end
    after_transition on: :approve, do: :approve!

    after_transition(&:commit_audit_log)
    after_failure(&:commit_audit_log)
  end

  dataset_module do
    def todo
      self.where(status: ["created", "in_progress"])
    end
  end

  def state_machine = @state_machine ||= Suma::StateMachine.new(self, :status)

  def start!
    admin = Suma.request_user_and_admin[1]
    self.update(owner: admin) if admin
  end

  def can_approve? = self.membership.verified? || self.membership.matched_organization

  def approve!
    return if self.membership.verified?
    self.membership.update(verified_organization: self.membership.matched_organization)
  end

  def begin_partner_outreach
    subject, body = _partner_outreach_content
    params = {
      subject:,
      body:,
      mode: "shared",
      should_add_default_signature: true,
    }
    if (author_id = self._front_author_id)
      params[:author_id] = author_id
    end
    if (partner_email = self.membership.organization_verification_email).present?
      # Do not use a resource alias here, it doesn't work right for some reason.
      params[:to] = [partner_email]
    end
    resp = Suma::Frontapp.client.create_draft!(self.class.front_partner_channel_id, params)
    self.partner_outreach_front_conversation_id = self._parse_conversation_id(resp)
    self.save_changes
  end

  def _partner_outreach_content
    front_template = self.membership.lookup_organization_field(:membership_verification_front_template_id, "")
    front_template = self.class.front_partner_default_template_id if front_template.blank?
    if front_template.blank?
      member = self.membership.member
      body = [
        "Verification information for <strong>#{member.name}</strong>",
      ]
      body << "Phone: #{member.us_phone}" if member.phone
      body << "Address: #{member.legal_entity.address&.one_line_address}" if member.legal_entity.address
      body = "<p>" + body.join("<br />") + "</p>"
      return ["Verification request for #{member.name}", body]
    end
    front_template = Suma::Frontapp.to_api_id("rsp", front_template)
    tmpl = Suma::Frontapp.client.get_message_template(front_template)
    ctx = self.render_front_template_context(
      member: self.membership.member,
      handle: self.membership.organization_verification_email,
    )
    return self.render_front_template(tmpl, ctx)
  end

  def begin_member_outreach
    subject, body = self._member_outreach_content
    params = {
      subject:,
      body:,
      mode: "shared",
      should_add_default_signature: false,
      to: [
        # Use a resource alias for the user, the phone won't be associated directly.
        Suma::Frontapp.contact_phone_handle(self.membership.member.phone),
      ],
    }
    if (author_id = self._front_author_id)
      params[:author_id] = author_id
    end
    resp = Suma::Frontapp.client.create_draft!(self.class.front_member_channel_id, params)
    self.member_outreach_front_conversation_id = self._parse_conversation_id(resp)
    self.save_changes
  end

  def _member_outreach_content
    member = self.membership.member
    lang = member.preferences!.preferred_language
    front_template = ""
    if (tt = self.membership.lookup_organization_field(:membership_verification_member_outreach_template))
      # Use the localized translated text field from the organization.
      front_template = tt.send(lang)
    end
    # Fall back to the localized configured field
    front_template = self.class.send(:"front_member_default_#{lang}_template_id") if front_template.blank?
    if front_template.blank?
      # don't bother localizing this body
      return ["", "Hi #{member.name}"]
    end
    front_template = Suma::Frontapp.to_api_id("rsp", front_template)
    tmpl = Suma::Frontapp.client.get_message_template(front_template)
    ctx = self.render_front_template_context(member:)
    return self.render_front_template(tmpl, ctx)
  end

  def _parse_conversation_id(front_resp)
    return front_resp.fetch("_links").fetch("related").fetch("conversation").split("/").last
  end

  def _front_author_id
    (admin = Suma.request_user_and_admin.last) or return nil
    if admin.email.present?
      begin
        teammate = Suma::Frontapp.client.get_teammate Suma::Frontapp.contact_alt_handle("email", admin.email)
        return teammate.fetch("id")
      rescue Frontapp::NotFoundError
        nil
      end
    end
    if admin.phone.present?
      begin
        teammate = Suma::Frontapp.client.get_teammate Suma::Frontapp.contact_phone_handle(admin.phone)
        return teammate.fetch("id")
      rescue Frontapp::NotFoundError
        nil
      end
    end
    return nil
  end

  def front_partner_conversation_status = _front_conversation_status(:partner)
  def front_member_conversation_status = _front_conversation_status(:member)

  class ConversationStatus < Suma::TypedStruct
    attr_reader :web_url, :last_updated_at, :waiting_on_member, :waiting_on_admin, :initial_draft
  end

  def _front_conversation_status(sym)
    convo_id = self.send(:"#{sym}_outreach_front_conversation_id")
    return nil if convo_id.blank?
    params = {}
    if (msg = self.send(:"front_latest_#{sym}_message"))
      params[:web_url] = "https://app.frontapp.com/open/#{msg.front_id}"
      params[:last_updated_at] = msg.created_at
      params[:waiting_on_admin] = msg.data.fetch("is_inbound", false)
      params[:waiting_on_member] = !params[:waiting_on_admin]
      params[:initial_draft] = false
    else
      params[:web_url] = "https://app.frontapp.com/open/#{convo_id}"
      params[:last_updated_at] = nil
      params[:waiting_on_admin] = false
      params[:waiting_on_member] = false
      params[:initial_draft] = true
    end
    return ConversationStatus.new(**params)
  end

  def render_front_template_context(member:, handle: nil)
    admin = Suma.request_user_and_admin.last
    ctx = {
      # account.name: name of the contact currently tied to the account
      # conversation.id: numeric version of the conversation's ID
      # conversation.public_id: ID available in app menus (e.g. cnv_123abc)
      # conversation.ticket_id: ticket ID assigned to the conversation
      # message.id: numeric version of the message's ID
      # message.public_id: ID available in app menus (e.g. msg_123abc)
      recipient: {
        # recipient.handle: contact's handle (e.g. email, phone, etc.) dependent on message type
        handle:,
        # recipient.email: contact's email address
        email: member.email,
        # recipient.twitter: contact's X (formerly Twitter) handle
        # recipient.phone: contact's phone number
        phone: Suma::PhoneNumber.format_display(member.phone),
        # recipient.name: contact's full name
        name: member.name,
        # recipient.first_name: First part of contact's name, split on the first space.
        first_name: member.guessed_first_name,
        # recipient.last_name: Remaining portion of contact's name following the first space.
        last_name: member.guessed_last_name,
        # recipient.link: contact's link attribute
        custom: {
          address: member.legal_entity.address&.one_line_address,
        },
      },
      # survey: inserts Front's CSAT feature
      user: {
        # user.id: current Front user's numeric ID
        # user.name: current Front user's full name (first + last)
        name: admin&.name,
        # user.first_name: current Front user's first name
        first_name: admin&.guessed_first_name,
        # user.last_name: current Front user's last name
        last_name: admin&.guessed_last_name,
        # user.email: current Front user's email
        email: admin&.email,
      },
    }
    return ctx
  end

  def render_front_template(tmpl, ctx)
    subject = self.render_front_template_string(tmpl.fetch("subject"), ctx)
    body = self.render_front_template_string(tmpl.fetch("body"), ctx)
    return [subject, body]
  end

  # Using template text as the message body does not render it,
  # as when you use a message template while composing a message.
  # Front uses Liquid templates, so render it as Liquid with Front's
  # common drops we can replicate.
  # See https://help.front.com/en/articles/2306 for drops.
  def render_front_template_string(s, ctx)
    begin
      tmpl = Liquid::Template.parse(s)
    rescue Liquid::SyntaxError
      return s
    end
    ctx = ctx.deep_stringify_keys
    r = tmpl.render(ctx)
    return r
  end

  def find_duplicates = DuplicateFinder.lookup_matches(self)

  # Return the risk of the first duplicate, or nil.
  # Duplicates are stored sorted so we can use the 0th item.
  def duplicate_risk = self.find_duplicates.first&.max_risk

  def combined_notes = Suma::Support::Note.combine_instances(self.notes, self.membership.member.notes)

  def rel_admin_link = "/membership-verification/#{self.id}"

  def hybrid_search_fields
    super
    return [
      ["Member", self.membership.member.name],
      ["Organization", self.membership.organization_label],
      :status,
    ]
  end

  def before_save
    self.cached_duplicates_key = "" if self.column_change(:account_number)
    super
  end

  def after_save
    super
    Suma::SSE.publish(Suma::SSE::ORGANIZATION_MEMBERSHIP_VERIFICATIONS, {id: self.id})
  end

  def validate
    super
    validates_state_machine
  end
end

require_relative "verification/duplicate_finder"

# Table: organization_membership_verifications
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                                     | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                             | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                             | timestamp with time zone |
#  status                                 | text                     | NOT NULL
#  partner_outreach_front_conversation_id | text                     |
#  member_outreach_front_conversation_id  | text                     |
#  membership_id                          | integer                  | NOT NULL
#  owner_id                               | integer                  |
#  search_content                         | text                     |
#  search_embedding                       | vector(384)              |
#  search_hash                            | text                     |
#  account_number                         | text                     |
#  cached_duplicates_key                  | text                     | NOT NULL DEFAULT ''::text
#  cached_duplicates                      | jsonb                    | NOT NULL DEFAULT '[]'::jsonb
# Indexes:
#  organization_membership_verifications_pkey                      | PRIMARY KEY btree (id)
#  organization_membership_verifications_search_content_trigram_in | gist (search_content)
#  organization_membership_verifications_search_content_tsvector_i | gin (to_tsvector('english'::regconfig, search_content))
# Check constraints:
#  non_empty_account_number | (account_number IS NULL OR account_number <> ''::text)
# Foreign key constraints:
#  organization_membership_verifications_membership_id_fkey | (membership_id) REFERENCES organization_memberships(id)
#  organization_membership_verifications_owner_id_fkey      | (owner_id) REFERENCES members(id) ON DELETE SET NULL
# Referenced By:
#  organization_membership_verification_audit_logs     | organization_membership_verification_audit_verification_id_fkey | (verification_id) REFERENCES organization_membership_verifications(id) ON DELETE CASCADE
#  support_notes                                       | organization_membership_verification_notes_verification_id_fkey | (legacy_verification_id) REFERENCES organization_membership_verifications(id) ON DELETE CASCADE
#  support_notes_organization_membership_verifications | support_notes_organization_membership_veri_verification_id_fkey | (verification_id) REFERENCES organization_membership_verifications(id)
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
