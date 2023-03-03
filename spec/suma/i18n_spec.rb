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
    stub_const("Suma::Message::DATA_DIR", temp_dir_path)
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

    it "renders html entities" do
      path = described_class.strings_path("en")
      File.write(path, '{"x": "«&laquo;&#171;", "y": {"z": "«&laquo;&#171;"}')
      described_class.reformat_files
      expect(File.read(path)).to eq("{\n  \"x\": \"«««\",\n  \"y\": {\n    \"z\": \"«««\"\n  }\n}")
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

  describe "ensure_english_interpolation_values" do
    it "ensures dynamic values are not changed" do
      spanish_dynamic_str = "Precio es {{precio}}."
      english_dynamic_str = "Price is {{price}}."
      expect(described_class.ensure_english_interpolation_values(spanish_dynamic_str, english_dynamic_str,
                                                                 "English",)).to eq("Precio es {{price}}.")
    end
    it "ensures multiple dynamic values are not changed" do
      spanish_dynamic_str = "Precio es {{precio}}. Salvaste {{suma}}."
      english_dynamic_str = "Price is {{price}}. You saved {{amount}}."
      expect(described_class.ensure_english_interpolation_values(spanish_dynamic_str, english_dynamic_str,
                                                                 "English",)).to eq("Precio es {{price}}. Salvaste {{amount}}.")
    end
    it "ensures strings starting with dynamic values are not changed" do
      spanish_dynamic_str = "{{precio, sumaCurrency}} x {{cantidad}}"
      english_dynamic_str = "{{price, sumaCurrency}} x {{quantity}}"
      expect(described_class.ensure_english_interpolation_values(spanish_dynamic_str, english_dynamic_str,
                                                                 "English",)).to eq(english_dynamic_str)
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

    it "renders html entities" do
      File.write(described_class.strings_path("en"), {dr: "&lsquo;evil&#8217;"}.to_json)
      File.write(described_class.strings_path("es"), {dr: "&lsquo;evil&#8217;"}.to_json)
      out = +""
      described_class.prepare_csv("es", output: out)
      expect(out).to eq("Key,Spanish,English\ndr,‘evil’,‘evil’\n")
    end

    it "includes messages" do
      Dir.mkdir(temp_dir_path + "templates")
      Dir.mkdir(temp_dir_path + "templates/subdir")
      File.write(temp_dir_path + "templates/tmpl.en.sms.liquid", "english sms 1")
      File.write(temp_dir_path + "templates/subdir/tmpl.en.sms.liquid", "english sms 2")
      File.write(temp_dir_path + "templates/tmpl.es.sms.liquid", "spanish sms 1")
      File.write(temp_dir_path + "templates/subdir/tmpl.es.sms.liquid", "spanish sms 2")
      out = +""
      described_class.prepare_csv("es", output: out)
      expect(out).to eq("Key,Spanish,English\n" \
                        "message:/templates/subdir/tmpl.sms,spanish sms 2,english sms 2\n" \
                        "message:/templates/tmpl.sms,spanish sms 1,english sms 1\n")
    end
  end

  describe "import_csv" do
    it "applies csv data to stored locale json" do
      path = described_class.strings_path("es")
      File.write(path, '{"x":1}') # Make sure it gets blown away
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

    it "overwrites message templates" do
      csv = "Key,Spanish,English\n" \
            "message:/templates/subdir/tmpl.sms,spanish sms 2,english sms 2\n" \
            "message:/templates/tmpl.sms,spanish sms 1,english sms 1\n"
      described_class.import_csv(input: csv)
      expect(File.read(Suma::Message::DATA_DIR + "templates/subdir/tmpl.es.sms.liquid").strip).to eq("spanish sms 2")
      expect(Pathname(Suma::Message::DATA_DIR + "templates/subdir/tmpl.en.sms.liquid")).to_not exist
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

  describe "convert_source_to_resource_files" do
    it "converts all source files" do
      src = described_class::LOCALE_DIR + "en/source/foo.md"
      dst = described_class::LOCALE_DIR + "en/foo.json"
      Dir.mkdir(temp_dir_path + "en/source")
      File.write(src, "# title\n\nfirst \"para")
      described_class.convert_source_to_resource_files
      expect(File.read(dst)).to eq("{\n  \"contents\": \"# title\\n\\nfirst \\\"para\"\n}")
    end
  end
end
