# frozen_string_literal: true

RSpec.describe "Suma::Member::Session", :db do
  let(:described_class) { Suma::Member::Session }

  it "can fixture a valid instance" do
    Suma::Fixtures.session.create
  end
end
