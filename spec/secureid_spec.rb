# frozen_string_literal: true

require "suma/secureid"

RSpec.describe Suma::Secureid do
  it "can generate a token" do
    expect(described_class.new_token).to have_length(be_between(24, 26))
    expect(described_class.new_short_token).to have_length(be_between(6, 7))
  end
end
