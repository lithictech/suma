# frozen_string_literal: true

RSpec.describe "Suma::Organization", :db do
  let(:described_class) { Suma::Organization }

  it "creates an organization" do
    p = Suma::Fixtures.organization(name: "Hacienda ABC").create
    expect(p).to have_attributes(name: "Hacienda ABC")
  end
end
