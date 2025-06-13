# frozen_string_literal: true

RSpec.describe "Suma::Message", :db do
  it "can render templates" do
    r = Suma::Fixtures.member.create
    expect { Suma::Messages::OrderConfirmation.fixtured(r) }.to_not raise_error
    expect { Suma::Messages::SingleValue.fixtured(r) }.to_not raise_error
    expect { Suma::Messages::Verification.fixtured(r) }.to_not raise_error
  end
end
