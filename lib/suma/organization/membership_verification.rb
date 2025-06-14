# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"
require "suma/postgres/hybrid_search"

class Suma::Organization::MembershipVerification < Suma::Postgres::Model(:organization_membership_verifications)
  include Appydays::Configurable
  include Suma::AdminLinked
  include Suma::Postgres::HybridSearch

  class Message < Suma::TypedStruct
    attr_reader :url, :at
  end

  configurable(:verifications) do
    setting :front_partner_channel_id, ""
    setting :front_member_channel_id, ""
  end

  plugin :hybrid_search
  plugin :state_machine
  plugin :timestamps

  one_to_many :audit_logs,
              class: "Suma::Organization::MembershipVerificationAuditLog",
              order: Sequel.desc(:at),
              key: :verification_id
  many_to_one :membership, class: "Suma::Organization::Membership"
  many_to_one :owner, class: "Suma::Member"

  state_machine :status, initial: :created do
    state :created,
          :in_progress,
          :verified,
          :ineligible,
          :abandoned

    event :start do
      transition created: :in_progress
    end
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
      transition in_progress: :verified
    end

    after_transition(&:commit_audit_log)
    after_failure(&:commit_audit_log)
  end

  dataset_module do
    def todo
      self.where(status: ["created", "in_progress"]).order(:created_at, :id)
    end
  end

  def begin_partner_outreach
    member = self.membership.member
    body = <<~S
      Verification information for #{member.name}
      Phone: #{member.us_phone}
      Address: #{member.legal_entity.address&.one_line_address}
    S
    params = {
      subject: "Verification request for #{member.name}",
      body:,
      mode: "shared",
      should_add_default_signature: true,
    }
    if (author_id = self._front_author_id)
      params[:author_id] = author_id
    end
    got = Suma::Frontapp.client.create_draft!(self.class.front_partner_channel_id, params)
    self.partner_outreach_front_response = got
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
    got = Suma::Frontapp.client.create_draft!(self.class.front_member_channel_id, params)
    self.member_outreach_front_response = got
    self.save_changes
  end

  def _front_author_id
    (admin = Suma.request_user_and_admin.last) or return nil
    return Suma::Frontapp.contact_phone_handle(admin.phone)
  end

  def last_partner_response
    # Find message in WHDB
  end

  def latest_member_response
    # Find message in WHDB
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
end
