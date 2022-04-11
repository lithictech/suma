# frozen_string_literal: true

RSpec.describe "Suma::Organization", :db do
  let(:described_class) { Suma::Organization }

  it "creates a slug automatically" do
    p = Suma::Fixtures.organization(name: "Code The Dream").create
    expect(p).to have_attributes(slug: "code_the_dream")
  end
end
