# frozen_string_literal: true

require "suma/url_shortener"

RSpec.describe Suma::UrlShortener do
  it "returns the shortener (even if disabled)", reset_configuration: Suma::UrlShortener do
    described_class.disabled = true
    expect(described_class).to_not be_enabled
    expect(described_class.shortener).to be_a(UrlShortener)
  end
end
