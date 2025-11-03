# frozen_string_literal: true

# Logic that runs when a member sees reduction in program access;
# for example, losing a role, getting an expired organization membership,
# having a direct enrollment removed, etc.
#
# Each removal calculation can be somewhat slow, so the removal is done asynchronously-
# users will lose the ability to see a program immediately, but secondary effects
# like closing a vendor account will happen afterwards.
#
# We haven't figured out a generic way to process un-enrollments,
# since there is a lot of nuance with how resources can be shared.
#
# For example, we don't want to remove someone from a Lyft Pass program
# if they have access to any program using it; we don't want to close
# someone's Lime account if any program gives them access to a Lime vendor service.
#
# So this logic is closely coupled to knowing about what external resources
# may need revocation.
class Suma::Program::EnrollmentRemover
  attr_accessor :before_enrollments, :after_enrollments, :removed_enrollments

  def initialize(member)
    @member = member
  end

  def reenroll(&block)
    @reenroll_block = block
    return self
  end

  private def check_transaction!
    Suma::Postgres.check_transaction(
      @member.db,
      "Removal has side effects, and should be idempotent, so cannot use a transaction.",
    )
  end

  def process
    raise LocalJumpError, "must first call reenroll with a block" unless @reenroll_block
    check_transaction!
    @member.db.transaction(rollback: :always) do
      m2 = Suma::Member[@member.id]
      @reenroll_block.call(m2)
      @before_enrollments = m2.combined_program_enrollments.select(&:enrolled?)
    end
    @after_enrollments = @member.combined_program_enrollments.select(&:enrolled?)
    @removed_enrollments = @before_enrollments - @after_enrollments

    @before_configs = @before_enrollments.map(&:program).flat_map(&:anon_proxy_vendor_configurations).uniq
    @after_configs = @after_enrollments.map(&:program).flat_map(&:anon_proxy_vendor_configurations).uniq
    @removed_configs = @before_configs - @after_configs
    self._close_lime_account
    self._revoke_lyft_pass
    return self
  end

  protected def _close_lime_account
    was_in_lime = @before_configs.any? { |vc| vc.auth_to_vendor_key == "lime" }
    still_in_lime = @after_configs.any? { |vc| vc.auth_to_vendor_key == "lime" }
    return unless was_in_lime && !still_in_lime
    self.close_lime_accounts
  end

  # Remove member access to all Lime AnonProxy accounts in suma (generally just one).
  # This sets the account as pending closure, then requests a new magic link.
  # When the link is received (see +Suma::AnonProxy::MessageHandler::Lime+),
  # we exchange the token, which logs the user out of all other devices,
  # and un-mark the account as pending closure.
  #
  # It also trashes the existing member contact tied to the vendor account,
  # so the user can log in with a new valid account (since the old account
  # is logged out of the device for 90 days as per Lime).
  #
  # This method is idempotent:
  # - vendor accounts pending closure re-request a magic link (processing this is also idempotent);
  # - vendor accounts already closed no longer have a member contact so are skipped.
  #
  def close_lime_accounts
    check_transaction!
    lime_configs = Suma::AnonProxy::VendorConfiguration.where(auth_to_vendor_key: "lime").all
    vendor_accounts = @member.anon_proxy_vendor_accounts_dataset.
      where(configuration: lime_configs).
      exclude(contact_id: nil).
      all
    return if vendor_accounts.empty?
    # Update accounts by ID to make sure we're looking at a consistent set of rows.
    Suma::AnonProxy::VendorAccount.where(id: vendor_accounts.map(&:id)).update(pending_closure: true)
    # Request a new magic link for each account. See method doc for explanation.
    vendor_accounts.each do |va|
      Suma::AnonProxy::AuthToVendor::Lime.new(va).auth
    end
  end

  # Revoking lyft pass is complex for a couple reasons:
  #
  # First, we can't just revoke access to any unenrolled programs;
  # we need to make sure the member cannot still access that lyft pass program from a different suma program.
  # We only revoke access to lyft passes the member can no longer access at all.
  #
  # Second, and more confusingly, we need to update the VendorAccount tied to the LyftPass vendor configuration,
  # to un-mark the member as registered in that lyft pass program. This way, if the member gains new access
  # to this lyft pass program id, the correct code paths (prompting them to 'link' their account,
  # and thus regain access to Lyft Pass) will run.
  def _revoke_lyft_pass
    previous_pass_ids = @before_enrollments.map { |e| e.program.lyft_pass_program_id }.select(&:present?)
    current_pass_ids = @after_enrollments.map { |e| e.program.lyft_pass_program_id }.select(&:present?)
    removed_pass_ids = previous_pass_ids - current_pass_ids
    return if removed_pass_ids.empty?
    registrations = Suma::AnonProxy::VendorAccountRegistration.where(
      external_program_id: removed_pass_ids,
      account: @member.anon_proxy_vendor_accounts_dataset.where(
        configuration: Suma::AnonProxy::VendorConfiguration.where(auth_to_vendor_key: "lyft_pass"),
      ),
    ).all
    self.revoke_lyft_passes(registrations)
  end

  # Revoke access to all Lyft Pass programs.
  # Generally this is only used for global changes,
  # like when a user loses access to services due to a negative ledger.
  def revoke_all_lyft_passes
    registrations = Suma::AnonProxy::VendorAccountRegistration.where(
      account: @member.anon_proxy_vendor_accounts_dataset.where(
        configuration: Suma::AnonProxy::VendorConfiguration.where(auth_to_vendor_key: "lyft_pass"),
      ),
    ).all
    self.revoke_lyft_passes(registrations)
  end

  # Revoke the member's access to the Lyft Pass programs represented by
  # the registrations. Registrations are destroyed when revoked,
  # so the member can be granted access to the program again when the suma app allows it.
  #
  # This method is idempotent:
  # - After revoking registration in a program, the registration is destroyed.
  #   At this point, we won't try to re-revoke it.
  #
  # @param [Array<Suma::AnonProxy::VendorAccountRegistration>] registrations
  def revoke_lyft_passes(registrations)
    check_transaction!
    return if registrations.empty?
    lp = Suma::Lyft::Pass.from_config
    lp.authenticate
    registrations.each do |r|
      member = r.account.member
      # If we're running this after member deletion, use their previous phone as what was previous valid.
      phone = member.soft_deleted? ? member.previous_phones.first : member.phone
      lp.revoke_member(r.account.member, program_id: r.external_program_id, phone:) if phone
      r.destroy
    end
  end
end
