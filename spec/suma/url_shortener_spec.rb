# frozen_string_literal: true

require "suma/url_shortener"

RSpec.describe Suma::UrlShortener do
  it "returns nil for the shortener if disabled", reset_configuration: Suma::UrlShortener do
    described_class.disabled = true
    expect(described_class.shortener).to be_nil
    described_class.disabled = false
    expect(described_class.shortener).to be_a(UrlShortener)
  end
end
