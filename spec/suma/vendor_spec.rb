# frozen_string_literal: true

RSpec.describe "Suma::Vendor", :db do
  let(:described_class) { Suma::Vendor }

  it "creates a slug automatically" do
    p = Suma::Fixtures.vendor(name: "Code The Dream").create
    expect(p).to have_attributes(slug: "code_the_dream")
  end
end
