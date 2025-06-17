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
  end

  plugin :hybrid_search
  plugin :state_machine
  plugin :timestamps

  many_to_one :membership, class: "Suma::Organization::Membership"
  one_to_many :audit_logs,
              class: "Suma::Organization::Membership::VerificationAuditLog",
              order: Sequel.desc(:at),
              key: :verification_id
  one_to_many :notes,
              class: "Suma::Organization::Membership::VerificationNote",
              order: Sequel.desc(:created_at),
              key: :verification_id
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
      self.where(status: ["created", "in_progress"]).order(:created_at, :id)
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
    member = self.membership.member
    body = [
      "Verification information for <strong>#{member.name}</strong>",
    ]
    body << "Phone: #{member.us_phone}" if member.phone
    body << "Address: #{member.legal_entity.address&.one_line_address}" if member.legal_entity.address
    params = {
      subject: "Verification request for #{member.name}",
      body: "<p>" + body.join("<br />") + "</p>",
      mode: "shared",
      should_add_default_signature: true,
    }
    if (author_id = self._front_author_id)
      params[:author_id] = author_id
    end
    if (partner_email = self.membership.organization_verification_email).present?
      params[:to] = [partner_email]
    end
    resp = Suma::Frontapp.client.create_draft!(self.class.front_partner_channel_id, params)
    self.partner_outreach_front_conversation_id = self._parse_conversation_id(resp)
    self.save_changes
  end

  def begin_member_outreach
    params = {
      body: "TK",
      mode: "shared",
      should_add_default_signature: false,
    }
    if (author_id = self._front_author_id)
      params[:author_id] = author_id
    end
    resp = Suma::Frontapp.client.create_draft!(self.class.front_member_channel_id, params)
    self.member_outreach_front_conversation_id = self._parse_conversation_id(resp)
    self.save_changes
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

  def rel_admin_link = "/membership-verification/#{self.id}"

  def hybrid_search_fields
    super
    return [
      ["Member", self.membership.member.name],
      ["Organization", self.membership.organization_label],
      :status,
    ]
  end

  def after_save
    super
    Suma::SSE.publish(Suma::SSE::ORGANIZATION_MEMBERSHIP_VERIFICATIONS, {id: self.id})
  end
end
