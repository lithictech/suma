# frozen_string_literal: true

RSpec.describe "Suma::TranslatedText", :db do
  let(:described_class) { Suma::TranslatedText }

  describe "empty" do
    it "returns a cached empty instance" do
      e1 = described_class.empty
      expect(e1).to_not be_new
      e2 = described_class.empty
      expect(e1).to be(e2)
    end
  end

  describe "format" do
    it "returns a new instance with text fields formatted" do
      base = Suma::TranslatedText.create(all: "{{x}} {{ y }} {{ z}} {{w}}")
      f1 = base.format(x: 1, y: 2, z: 3)
      expect(f1).to have_attributes(en: "1 2 3 {{w}}", es: "1 2 3 {{w}}")
      expect(f1).to be_new
    end
  end

  describe "format!" do
    it "returns an existing or newly saved instance with the text fields formatted" do
      base = Suma::TranslatedText.create(all: "{{x}} {{ y }} {{ z}} {{w}}")
      f1 = base.format!(x: 1, y: 2, z: 3)
      expect(f1).to have_attributes(en: "1 2 3 {{w}}", es: "1 2 3 {{w}}")
      expect(f1).to_not be_new
      f2 = base.format!(x: 1, y: 2, z: 3)
      expect(f2).to be === f1
      f3 = base.format!(x: 1)
      expect(f3).to_not be === f1
    end
  end
end
