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
    import_localized_message_seeds
    msg = Suma::Messages::Testers::Localized.new
    msg.language = "es"
    Suma::Fixtures.static_string.message(msg, :sms).text("", es: "hola").create
    deliveries = Suma::Fixtures.member.create.message_preferences!.update(preferred_language: "es").dispatch(msg)
    expect(deliveries).to contain_exactly(have_attributes(template: "specs/localized", template_language: "es"))
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

  it "can describe subscription groups" do
    pref = Suma::Fixtures.member.create.message_preferences!
    expect(pref.subscriptions).to have_length(3)
  end
end
