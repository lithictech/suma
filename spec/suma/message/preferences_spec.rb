# frozen_string_literal: true

require "suma/messages/specs"

RSpec.describe "Suma::Message::Preferences", :db, :messaging do
  let(:described_class) { Suma::Message::Preferences }

  it "creates correct defaults" do
    pref = Suma::Fixtures.member.create.message_preferences!
    expect(pref).to have_attributes(
      sms_enabled: true,
      email_enabled: false,
      preferred_language: "en",
    )
  end

  it "dispatches correctly using configured settings" do
    msg = Suma::Messages::Testers::Localized.new
    deliveries = Suma::Fixtures.member.create.message_preferences!.update(preferred_language: "fr").dispatch(msg)
    expect(deliveries).to contain_exactly(have_attributes(template: "specs/localized", template_language: "fr"))
  end
end
