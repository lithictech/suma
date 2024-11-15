# frozen_string_literal: true

RSpec.describe "Suma::AnonProxy::VendorConfiguration", :db do
  let(:described_class) { Suma::AnonProxy::VendorConfiguration }

  describe "associations" do
    it "knows its program enrollments" do
      e1 = Suma::Fixtures.program_enrollment.create
      e2 = Suma::Fixtures.program_enrollment.create
      e3 = Suma::Fixtures.program_enrollment.create

      o = Suma::Fixtures.anon_proxy_vendor_configuration.create
      o.add_program(e1.program)
      o.add_program(e2.program)
      expect(o.program_enrollments).to have_same_ids_as(e1, e2)
    end
  end
end
