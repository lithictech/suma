# frozen_string_literal: true

require "suma/lyft/pass"

class Suma::AnonProxy::AuthToVendor::LyftPass < Suma::AnonProxy::AuthToVendor
  def auth
    now = Time.now.utc
    enrollments, registered = self.enrollments_requiring_attention(now:)
    unless enrollments.empty?
      lp = Suma::Lyft::Pass.from_config
      lp.authenticate
      enrollments.each do |pe|
        program_id = pe.program.lyft_pass_program_id
        lp.invite_member(self.vendor_account.member, program_id:)
        registered[program_id] = now.iso8601
      end
    end
    self.vendor_account.update(registered_with_vendor: registered.to_json)
  end

  def needs_polling? = false

  def needs_attention?(now:)
    self.vendor_account.registered_with_vendor.blank? ||
      self.enrollments_requiring_attention(now:)[0].any?
  end

  # Return a tuple of <array of enrollments> and <parsed registered_with_vendor>
  def enrollments_requiring_attention(now:)
    begin
      registered = JSON.parse(self.vendor_account.registered_with_vendor)
    rescue JSON::ParserError, TypeError
      registered = {}
    end
    registered = {} unless registered.is_a?(Hash)
    unregistered_programs = Suma::Lyft::Pass.programs_dataset.exclude(lyft_pass_program_id: registered.keys)
    enrollments = self.vendor_account.member.combined_program_enrollments_dataset.
      active(as_of: now).
      where(program_id: unregistered_programs.select(:id)).
      all
    return enrollments, registered
  end
end
