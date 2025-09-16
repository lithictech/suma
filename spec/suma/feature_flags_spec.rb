# frozen_string_literal: true

RSpec.describe Suma::FeatureFlags, :db, reset_configuration: Suma::FeatureFlags do
  describe "checking" do
    let(:m) { Suma::Fixtures.member.create }
    let(:flag) { described_class::Flag.new(:test_flag) }

    before(:each) do
      stub_const("Suma::RACK_ENV", "development")
      @calls = []
    end

    def append_call
      @calls << 1
      return nil
    end

    it "runs the block if the member has a role with the configured name" do
      described_class.test_flag = ["role1"]

      flag.check(m) { append_call }
      expect(@calls).to be_empty

      m.add_role Suma::Fixtures.role.create(name: "role1")
      flag.check(m) { append_call }
      expect(@calls).to contain_exactly(1)

      described_class.test_flag = []
      flag.check(m) { append_call }
      expect(@calls).to contain_exactly(1)
    end

    it "returns the given default value if the block is not run" do
      described_class.test_flag = ["role1"]

      expect(flag.check(m, 5) { 1 }).to eq(5)
      m.add_role Suma::Fixtures.role.create(name: "role1")
      expect(flag.check(m, 5) { 1 }).to eq(1)
    end

    it "raises if the block and default are different types" do
      stub_const("Suma::RACK_ENV", "test")
      expect(flag.check(m, true) { true }).to eq(true)
      expect(flag.check(m, false) { true }).to eq(true)
      expect { flag.check(m, 5) { true } }.to raise_error(Suma::InvalidPostcondition)
    end

    it "always runs during tests" do
      flag.check(m) { append_call }
      expect(@calls).to eq([])

      stub_const("Suma::RACK_ENV", "test")
      flag.check(m) { append_call }
      expect(@calls).to eq([1])
    end

    it "raises if member is nil" do
      expect { flag.check(nil) }.to raise_error(Suma::InvalidPrecondition)
    end
  end
end
