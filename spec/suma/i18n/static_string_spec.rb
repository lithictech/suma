# frozen_string_literal: true

RSpec.describe "Suma::I18n::StaticString", :db do
  let(:described_class) { Suma::I18n::StaticString }

  describe "load_namespace_locale" do
    it "writes raw strings for the namespace" do
      Suma::Fixtures.static_string.text("there").create(namespace: "n1", key: "x.s1")
      Suma::Fixtures.static_string.text("hi ${x.s1}").create(namespace: "n1", key: "x.y.s2")
      Suma::Fixtures.static_string.text.create(key: "s1", namespace: "n2")

      j = described_class.load_namespace_locale(locale: "en", namespace: "n1")
      expect(j).to eq({"x" => {"s1" => "there", "y" => {"s2" => "hi ${x.s1}"}}})
    end

    it "does not include deprecated strings" do
      Suma::Fixtures.static_string.text.create(deprecated: true, namespace: "n1")
      j = described_class.load_namespace_locale(locale: "en", namespace: "n1")
      expect(j).to eq({})
    end

    it "uses empty string for rows with a null translated_text" do
      Suma::Fixtures.static_string.create(namespace: "n1", key: "s")
      j = described_class.load_namespace_locale(locale: "en", namespace: "n1")
      expect(j).to eq({"s" => ""})
    end
  end

  describe "fetch_modified_namespaces" do
    it "fetches namespaces modified after the given time" do
      Suma::Fixtures.static_string.create(namespace: "n1", deprecated: true)
      Suma::Fixtures.static_string.create(namespace: "n2", modified_at: 10.hours.ago)
      Suma::Fixtures.static_string.create(namespace: "n2", modified_at: 2.hours.ago)
      Suma::Fixtures.static_string.create(namespace: "n3", modified_at: 2.hours.ago)
      Suma::Fixtures.static_string.create(namespace: "n4", modified_at: 1.hour.ago, deprecated: true)
      Suma::Fixtures.static_string.create(namespace: "n5", modified_at: 10.hours.ago)

      expect(described_class.fetch_modified_namespaces(3.hours.ago)).to contain_exactly("n2", "n3")
    end
  end

  describe "validations" do
    it "errors for invalid keys or namespaces" do
      Suma::Fixtures.static_string.create(namespace: "n1", key: "s1")
      Suma::Fixtures.static_string.create(namespace: "n1.n2", key: "s1.s2")
      Suma::Fixtures.static_string.create(namespace: "n1_n2", key: "s1.s2")

      expect do
        Suma::Fixtures.static_string.create(namespace: "n1:n2")
      end.to raise_error(Sequel::ValidationFailed, "namespace is invalid")
      expect do
        Suma::Fixtures.static_string.create(key: "s1:s2")
      end.to raise_error(Sequel::ValidationFailed, "key is invalid")
      expect do
        Suma::Fixtures.static_string.create(key: "s1 s2", namespace: "n1-n2")
      end.to raise_error(Sequel::ValidationFailed, "key is invalid, namespace is invalid")
    end
  end

  describe "needs_text?" do
    it "is true if there is no text" do
      expect(Suma::Fixtures.static_string.instance).to be_needs_text
    end

    it "is true if any supported locale is blank", reset_configuration: Suma::I18n do
      s = Suma::Fixtures.static_string.text("x", es: "x").create
      expect(s).to_not be_needs_text
      s.text.en = " "
      expect(s).to be_needs_text
      Suma::I18n.enabled_locale_codes = ["es"]
      expect(s).to_not be_needs_text
    end
  end
end
