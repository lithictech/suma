# frozen_string_literal: true

RSpec.describe "Suma::Market", :db do
  let(:described_class) { Suma::Market }

  it "creates a slug automatically" do
    p = Suma::Fixtures.market(name: "Portland").create
    expect(p).to have_attributes(slug: "portland")
  end
end
