# frozen_string_literal: true

RSpec.describe "Suma::Role", :db do
  let(:described_class) { Suma::Role }

  describe "ensure!" do
    let(:role) { described_class.create(name: "foo") }
    let(:has_role) { Suma::Fixtures.organization.create }

    it "adds the role and returns true" do
      expect(role.ensure!(has_role)).to be(true)
      expect(has_role.roles).to contain_exactly(role)
    end

    it "noops and returns false if already assigned" do
      has_role.add_role(role)
      expect(role.ensure!(has_role)).to be(false)
      expect(has_role.roles).to contain_exactly(role)
    end

    it "noops and returns false for a constraint violation" do
      has_role.add_role(role)
      # Clear the array so we don't see what was just created, and re-add it.
      has_role.roles.clear
      expect(role.ensure!(has_role)).to be(false)
      expect(has_role.refresh.roles).to contain_exactly(role)
    end
  end
end
