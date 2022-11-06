# frozen_string_literal: true

require "suma/i18n"

RSpec.describe Suma::I18n, :db do
  include_context "uses temp dir"

  nested_hash = {
    "x" => 1,
    "y" => {
      "b" => 1,
      "a" => 2,
    },
    "h" => 3,
  }

  before(:each) do
    stub_const("Suma::I18n::LOCALE_DIR", temp_dir_path)
    Dir.mkdir(temp_dir_path + "en")
    Dir.mkdir(temp_dir_path + "es")
  end

  describe "reformat files" do
    it "reformats the files" do
      path = described_class.strings_path("en")
      File.write(path, '{"x": 1, "y":{"b":1, "a":2}, "h": 3}')
      described_class.reformat_files
      expect(File.read(path)).to eq(<<~J.rstrip)
        {
          "h": 3,
          "x": 1,
          "y": {
            "a": 2,
            "b": 1
          }
        }
      J
    end
  end

  describe "sort_hash" do
    it "sorts a nested hash" do
      expect(described_class.sort_hash(nested_hash).to_json).to eq('{"h":3,"x":1,"y":{"a":2,"b":1}}')
    end
  end

  describe "flatten_hash" do
    it "flattens a hash" do
      expect(described_class.flatten_hash(nested_hash)).to eq({"h" => 3, "x" => 1, "y:a" => 2, "y:b" => 1})
    end
  end

  describe "prepare_csv" do
    it "merges lang-specific data to base data and writes" do
      File.write(described_class.strings_path("en"), {hi: "Hi", greeting: {bye: "Bye"}}.to_json)
      File.write(described_class.strings_path("es"), {greeting: {bye: "Adiós"}}.to_json)
      out = +""
      described_class.prepare_csv("es", output: out)
      expect(out).to eq("Key,Spanish,English\ngreeting:bye,Adiós,Bye\nhi,,Hi\n")
    end
  end

  describe "import_csv" do
    it "applies csv data to stored locale json" do
      path = described_class.strings_path("es")
      File.write(path, '{"x":1}')
      csv = "Key,Spanish,English\ngreeting:bye,Adiós,Bye\nhi,,Hi\n"
      described_class.import_csv(input: csv)
      expect(File.read(path)).to eq(<<~J.rstrip)
        {
          "greeting": {
            "bye": "Adiós"
          }
        }
      J
    end
  end

  describe "export_dynamic" do
    it "exports all dynamic strings" do
      t1 = Suma::Fixtures.translated_text(en: "a1", es: "a2").create
      t2 = Suma::Fixtures.translated_text(en: "b1", es: "b2").create
      out = +""
      described_class.export_dynamic(output: out)
      expect(out).to eq("Id,English,Spanish\n#{t1.id},a1,a2\n#{t2.id},b1,b2\n")
    end
  end

  describe "import_dynamic" do
    it "imports dynamic strings" do
      t1 = Suma::Fixtures.translated_text(en: "a1", es: "a2").create
      t2 = Suma::Fixtures.translated_text(en: "b1", es: "b2").create
      inp = "Id,English,Spanish\n#{t1.id},x1,x2\n#{t2.id},y1,y2\n"
      described_class.import_dynamic(input: StringIO.new(inp))
      expect(Suma::TranslatedText.all).to contain_exactly(
        have_attributes(en: "x1", es: "x2"),
        have_attributes(en: "y1", es: "y2"),
      )
    end

    it "errors if an id is provided that does not exist" do
      t1 = Suma::Fixtures.translated_text(en: "a1", es: "a2").create
      inp = "Id,English,Spanish\n#{t1.id},x1,x2\n0,y1,y2\n"
      expect do
        described_class.import_dynamic(input: StringIO.new(inp))
      end.to raise_error(described_class::InvalidInput, /CSV had 2 rows but only matched 1 database rows/)
      expect(Suma::TranslatedText.all).to contain_exactly(
        have_attributes(en: "a1", es: "a2"),
      )
    end

    it "errors if columns mismatch" do
      inp = "Id,English,Spanish,French\n"
      expect do
        described_class.import_dynamic(input: StringIO.new(inp))
      end.to raise_error(described_class::InvalidInput, /Headers should be: Id,English/)
    end
  end
end
