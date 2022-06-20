# frozen_string_literal: true

require "suma/i18n"

RSpec.describe Suma::I18n do
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
end
