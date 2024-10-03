# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Program::Enrollment < Suma::Postgres::Model(:program_enrollments)
  many_to_one :program, class: "Suma::Program"
  many_to_one :member, class: "Suma::Member"

  dataset_module do
    def active
      return self.where(program: Suma::Program.dataset.active, unenrolled_at: nil).exclude(approved_at: nil)
    end
  end
end
