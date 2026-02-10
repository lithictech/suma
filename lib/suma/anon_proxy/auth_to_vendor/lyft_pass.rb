# frozen_string_literal: true

require "suma/lyft/pass"

class Suma::AnonProxy::AuthToVendor::LyftPass < Suma::AnonProxy::AuthToVendor
  def auth(now:)
    programs = self.programs_requiring_attention(now:).to_a
    return unless programs.any?
    lp = Suma::Lyft::Pass.from_config
    lp.authenticate
    programs.each do |pr|
      lyft_program_id = pr.lyft_pass_program_id
      lp.invite_member(self.vendor_account.member, program_id: lyft_program_id)
      self.vendor_account.add_registration(external_program_id: lyft_program_id)
    end
  end

  def needs_polling? = false
  def needs_linking?(now:) = self.programs_requiring_attention(now:).any?

  # Return a dataset of programs where:
  # - There is a lyft program id on its program
  # - The lyft program id is not part of this vendor account's registrations
  def programs_requiring_attention(now:)
    registered_ids = self.vendor_account.registrations.map(&:external_program_id)
    unregistered_programs = Suma::Lyft::Pass.programs_dataset.exclude(lyft_pass_program_id: registered_ids)
    rows = unregistered_programs.fetch_eligible_to(self.vendor_account.member, as_of: now)
    return rows
  end
end
