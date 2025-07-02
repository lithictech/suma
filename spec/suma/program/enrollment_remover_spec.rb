# frozen_string_literal: true

RSpec.describe Suma::Program::EnrollmentRemover, :db do
  let(:member) { Suma::Fixtures.member.create }
  let(:instance) { described_class.new(member) }

  it "runs the preprocess block to capture before and after enrollments on the member and rolls back changes" do
    p1 = Suma::Fixtures.program.create
    p2 = Suma::Fixtures.program.create
    p1enroll = Suma::Fixtures.program_enrollment(member:).in(p1).create
    instance.reenroll do |m|
      # Refer to the same row, but NOT the same object in memory
      expect(m).to be === member
      expect(m.object_id).to_not eql(member.object_id)
      role = Suma::Role.create(name: "enrollmenttestrole")
      m.add_role(role)
      Suma::Fixtures.program_enrollment(role:).in(p2).create
    end
    instance.process
    # We added the 'removed' enrollment
    expect(instance.before_enrollments).to contain_exactly(
      have_attributes(program: p1), have_attributes(program: p2),
    )
    # We found only the existing enrollment
    expect(instance.after_enrollments).to contain_exactly(have_attributes(program: p1))
    # We calculated the removed enrollments correctly
    expect(instance.removed_enrollments).to contain_exactly(have_attributes(program: p2))
    # We rolled back any database changes
    expect(Suma::Program::Enrollment.all).to have_same_ids_as(p1enroll)
  end

  describe "lyft pass" do
    before(:each) do
      Suma::Lyft.reset_configuration

      Suma::ExternalCredential.create(
        service: "lyft-pass-access-token",
        expires_at: 5.hours.from_now,
        data: {body: {}, cookies: {}}.to_json,
      )

      Suma::Lyft.pass_authorization = "Basic xyz"
      Suma::Lyft.pass_email = "a@b.c"
      Suma::Lyft.pass_org_id = "1234"
    end

    it "revokes lyft pass and destroys registrations for lyft pass program ids the member no longer can access" do
      lyft_pass_config = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lyft_pass")
      lyft_pass_vendor_acct = Suma::Fixtures.anon_proxy_vendor_account.
        create(configuration: lyft_pass_config, member: member)
      reg1 = lyft_pass_vendor_acct.add_registration(external_program_id: "111")
      reg2 = lyft_pass_vendor_acct.add_registration(external_program_id: "222")

      p1_lp1 = Suma::Fixtures.program.create(lyft_pass_program_id: "111")
      p2_lp1 = Suma::Fixtures.program.create(lyft_pass_program_id: "111")
      p3_lp2 = Suma::Fixtures.program.create(lyft_pass_program_id: "222")

      p1enroll = Suma::Fixtures.program_enrollment(member:).in(p1_lp1).create
      instance.reenroll do
        Suma::Fixtures.program_enrollment(member:).in(p2_lp1).create
        Suma::Fixtures.program_enrollment(member:).in(p3_lp2).create
      end

      stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/revoke").
        with(body: hash_including("ride_program_id" => "222")).to_return(status: 200)

      instance.process
      expect(reg1).to_not be_destroyed
      expect(reg2).to be_destroyed
    end
  end

  describe "lime" do
    it "only processes removal if there are no enrollments in any lime programs" do
      p1 = Suma::Fixtures.program.create
      p2 = Suma::Fixtures.program.create
      vc = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lime")
      p1.add_anon_proxy_vendor_configuration(vc)
      p2.add_anon_proxy_vendor_configuration(vc)
      Suma::Fixtures.program_enrollment(member:, program: p1).create
      instance.reenroll do
        Suma::Fixtures.program_enrollment(member:, program: p2).create
      end
      expect { instance.process }.to_not raise_error
    end

    it "errors if they have lost access to any Lime program" do
      program = Suma::Fixtures.program.create
      vc = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lime")
      program.add_anon_proxy_vendor_configuration(vc)
      instance.reenroll do
        Suma::Fixtures.program_enrollment(member:, program:).create
      end
      expect { instance.process }.to raise_error(/TODO: Not sure how to handle this yet/)
    end
  end
end
