# frozen_string_literal: true

require "suma/i18n/static_string_io"

RSpec.describe Suma::I18n::StaticStringIO, :db do
  include_context "uses temp dir"

  describe "replace_seeds" do
    it "replaces all static strings in the database" do
      stub_const("Suma::I18n::StaticStringIO::SEEDS_DIR", temp_dir_path)
      Dir.mkdir(temp_dir_path + "en")
      Dir.mkdir(temp_dir_path + "es")
      File.write(temp_dir_path + "en/ns1.json", {a: {b: "hi", c: "cc"}}.to_json)
      File.write(temp_dir_path + "es/ns1.json", {a: {b: "hola"}}.to_json)
      described_class.replace_seeds
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "a.b", namespace: "ns1", text: have_attributes(en: "hi", es: "hola")),
        have_attributes(key: "a.c", namespace: "ns1", text: have_attributes(en: "cc")),
      )
      File.write(temp_dir_path + "en/ns1.json", {a: {b: "bye"}}.to_json)
      described_class.replace_seeds
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "a.b", namespace: "ns1", text: have_attributes(en: "bye", es: "hola")),
      )
    end
  end

  describe "import_seeds" do
    it "adds new rows and does not modify existing" do
      stub_const("Suma::I18n::StaticStringIO::SEEDS_DIR", temp_dir_path)
      Dir.mkdir(temp_dir_path + "en")
      Dir.mkdir(temp_dir_path + "es")
      File.write(temp_dir_path + "en/ns1.json", {a: {b: "hi", c: "cc"}}.to_json)
      File.write(temp_dir_path + "es/ns1.json", {a: {b: "hola"}}.to_json)
      described_class.import_seeds
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "a.b", namespace: "ns1", text: have_attributes(en: "hi", es: "hola")),
        have_attributes(key: "a.c", namespace: "ns1", text: have_attributes(en: "cc")),
      )
      File.write(temp_dir_path + "en/ns1.json", {a: {b: "bye", d: "yo"}}.to_json)
      described_class.import_seeds
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "a.b", namespace: "ns1", text: have_attributes(en: "hi", es: "hola")),
        have_attributes(key: "a.c", namespace: "ns1", text: have_attributes(en: "cc", es: "")),
        have_attributes(key: "a.d", namespace: "ns1", text: have_attributes(en: "yo", es: "")),
      )
    end
  end

  describe "export_seeds" do
    it "writes static strings" do
      stub_const("Suma::I18n::StaticStringIO::SEEDS_DIR", temp_dir_path)

      Suma::Fixtures.static_string.text("hi", es: "hola").create(key: "a.b", namespace: "n1")
      Suma::Fixtures.static_string.text("en1", es: "es1").create(key: "a.c", namespace: "n1")
      Suma::Fixtures.static_string.text("en2", es: "es2").create(key: "a.c", namespace: "n2")

      described_class.export_seeds

      expect(JSON.parse(File.read(temp_dir_path + "en/n1.json"))).to eq({"a.b" => "hi", "a.c" => "en1"})
      expect(JSON.parse(File.read(temp_dir_path + "es/n1.json"))).to eq({"a.b" => "hola", "a.c" => "es1"})
      expect(JSON.parse(File.read(temp_dir_path + "en/n2.json"))).to eq({"a.c" => "en2"})

      expect { described_class.export_seeds }.to_not raise_error
    end
  end
end
