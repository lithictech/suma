# frozen_string_literal: true

require "suma/program/service_revoker"

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

  def process
    raise LocalJumpError, "must first call reenroll with a block" unless @reenroll_block
    Suma::Program::ServiceRevoker.check_transaction!
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
    Suma::Program::ServiceRevoker.close_lime_accounts(@member)
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
    Suma::Program::ServiceRevoker.revoke_lyft_passes(registrations)
  end
end
