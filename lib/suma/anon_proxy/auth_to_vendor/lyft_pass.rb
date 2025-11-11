# frozen_string_literal: true

require "suma/lyft/pass"

class Suma::AnonProxy::AuthToVendor::LyftPass < Suma::AnonProxy::AuthToVendor
  def auth(now:)
    enrollments = self.enrollments_requiring_attention_dataset(now:).all
    return unless enrollments.any?
    lp = Suma::Lyft::Pass.from_config
    lp.authenticate
    enrollments.each do |pe|
      lyft_program_id = pe.program.lyft_pass_program_id
      lp.invite_member(self.vendor_account.member, program_id: lyft_program_id)
      self.vendor_account.add_registration(external_program_id: lyft_program_id)
    end
  end

  def needs_polling? = false
  def needs_linking?(now:) = !self.enrollments_requiring_attention_dataset(now:).empty?

  # Return a dataset of program enrollments where:
  # - There is a lyft program id on its program
  # - The lyft program id is not part of this vendor account's registrations
  def enrollments_requiring_attention_dataset(now:)
    registered_ids = self.vendor_account.registrations.map(&:external_program_id)
    unregistered_programs = Suma::Lyft::Pass.programs_dataset.exclude(lyft_pass_program_id: registered_ids)
    ds = self.vendor_account.member.combined_program_enrollments_dataset.
      active(as_of: now).
      where(program_id: unregistered_programs.select(:id))
    return ds
  end
end
