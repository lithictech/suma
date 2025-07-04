# frozen_string_literal: true

require "amigo/job"

class Suma::Async::EnrollmentRemovalRunner
  extend Amigo::Job

  on(/^suma\.((program\.enrollment\.updated)|(organization\.membership\.updated))$/)

  class << self
    attr_accessor :testing_last_ran_removers
  end

  def _perform(event)
    case event.name
      when "suma.program.enrollment.updated"
        enrollment = self.lookup_model(Suma::Program::Enrollment, event)
        case event.payload[1]
          when changed(:unenrolled_at, from: nil)
            removers = self.handle_direct_enrollment_unenrolled(enrollment)
          else
            return
        end
      when "suma.organization.membership.updated"
        membership = self.lookup_model(Suma::Organization::Membership, event)
        case event.payload[1]
          when changed(:verified_organization_id, to: nil)
            removers = [
              Suma::Program::EnrollmentRemover.new(membership.member).reenroll do
                membership.this.update(
                  unverified_organization_name: nil,
                  verified_organization_id: membership.former_organization_id,
                  former_organization_id: nil,
                  formerly_in_organization_at: nil,
                )
              end,
            ]
          else
            return
        end
      else
        raise NotImplementedError, "unhandled event: #{event.name}"
    end
    self.class.testing_last_ran_removers = removers if Suma::RACK_ENV == "test"
    return if removers.nil?
    removers.each(&:process)
  end

  def handle_direct_enrollment_unenrolled(enrollment)
    reenroll = ->(*) { enrollment.update(unenrolled_at: nil) }
    members = if enrollment.member
                [enrollment.member]
    elsif enrollment.organization
      enrollment.organization.memberships.map(&:member)
    else
      enrollment.role.members + enrollment.role.organizations.flat_map(&:memberships).map(&:member)
    end
    removers = members.uniq.map { |m| Suma::Program::EnrollmentRemover.new(m) }
    removers.each { |r| r.reenroll(&reenroll) }
    return removers
  end
end
