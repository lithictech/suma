# frozen_string_literal: true

RSpec.describe "Suma::PlatformPartner", :db do
  let(:described_class) { Suma::PlatformPartner }

  it "creates a slug automatically" do
    p = Suma::Fixtures.platform_partner(name: "Code The Dream").create
    expect(p).to have_attributes(short_slug: "code_the_dream")
  end
end
