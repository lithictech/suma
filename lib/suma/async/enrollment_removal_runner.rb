# frozen_string_literal: true

require "amigo/job"

class Suma::Async::EnrollmentRemovalRunner
  extend Amigo::Job

  on Regexp.new('^suma\.(' \
                '(program\.enrollment\.updated)' \
                '|(organization\.membership\.updated)' \
                '|(member\.role\.removed)' \
                '|(organization\.role\.removed)' \
                ")$")

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
      when "suma.member.role.removed"
        member = self.lookup_model(Suma::Member, event.payload[0])
        role = self.lookup_model(Suma::Role, event.payload[1])
        removers = [
          Suma::Program::EnrollmentRemover.new(member).reenroll do
            member.add_role(role)
          end,
        ]
      when "suma.organization.role.removed"
        organization = self.lookup_model(Suma::Organization, event.payload[0])
        role = self.lookup_model(Suma::Role, event.payload[1])
        removers = organization.memberships.map do |m|
          Suma::Program::EnrollmentRemover.new(m.member).reenroll do
            organization.add_role(role)
          end
        end
      else
        raise NotImplementedError, "unhandled event: #{event.name}"
    end
    self.class.testing_last_ran_removers = removers if Suma::RACK_ENV == "test"
    return if removers.nil?
    removers.each(&:process)
  end

  def handle_direct_enrollment_unenrolled(enrollment)
    removers = enrollment.members.map do |m|
      Suma::Program::EnrollmentRemover.new(m).reenroll { enrollment.update(unenrolled_at: nil) }
    end
    return removers
  end
end
