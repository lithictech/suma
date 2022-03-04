# frozen_string_literal: true

RSpec.describe "Suma::Customer::Session", :db do
  let(:described_class) { Suma::Customer::Session }

  it "can fixture a valid instance" do
    Suma::Fixtures.session.create
  end
end
