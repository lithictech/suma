# frozen_string_literal: true

RSpec.describe "Suma::Organization::Membership", :db do
  let(:described_class) { Suma::Organization::Membership }

  it "can fixture itself" do
    membership = Suma::Fixtures.organization_membership.create
    expect(membership).to be_a(described_class)
  end
end
