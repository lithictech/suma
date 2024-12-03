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

  it "dispatches correctly using configured settings", reset_configuration: Suma::I18n do
    Suma::I18n.enabled_locale_codes = ["en", "fr"]
    msg = Suma::Messages::Testers::Localized.new
    deliveries = Suma::Fixtures.member.create.message_preferences!.update(preferred_language: "fr").dispatch(msg)
    expect(deliveries).to contain_exactly(have_attributes(template: "specs/localized", template_language: "fr"))
  end

  describe "preferred_language_name" do
    it "returns the language name" do
      pref = Suma::Fixtures.member.create.message_preferences!
      pref.preferred_language = "es"
      expect(pref).to have_attributes(preferred_language_name: "Spanish")
    end

    it "uses a clear value if the message is set to an invalid locale" do
      pref = Suma::Fixtures.member.create.message_preferences!
      pref.preferred_language = "zz"
      expect(pref).to have_attributes(preferred_language_name: "Invalid (zz)")
    end
  end
end
