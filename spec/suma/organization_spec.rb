# frozen_string_literal: true

RSpec.describe "Suma::Organization", :db do
  let(:described_class) { Suma::Organization }

  it "creates an organization" do
    org = Suma::Fixtures.organization(name: "Hacienda ABC").create
    expect(org).to have_attributes(name: "Hacienda ABC")
  end
end
