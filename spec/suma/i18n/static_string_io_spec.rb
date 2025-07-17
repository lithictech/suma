# frozen_string_literal: true

require "suma/i18n/static_string_io"

RSpec.describe Suma::I18n::StaticStringIO, :db do
  include_context "uses temp dir"

  describe "import_seeds" do
    it "replaces all static strings in the database" do
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
      File.write(temp_dir_path + "en/ns1.json", {a: {b: "bye"}}.to_json)
      described_class.import_seeds
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "a.b", namespace: "ns1", text: have_attributes(en: "bye", es: "hola")),
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

  describe "import_all_keys" do
    it "imports namespaces for all files present" do
      Dir.mkdir(temp_dir_path + "strings")
      File.write(temp_dir_path + "strings/ns1.txt", "s1")
      File.write(temp_dir_path + "strings/ns2.txt", "s2")
      described_class.import_all_keys(temp_dir_path + "strings")
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "s1", namespace: "ns1"),
        have_attributes(key: "s2", namespace: "ns2"),
      )
    end
  end

  describe "import_namespace_keys" do
    let(:path) { temp_dir_path + "strings.txt" }

    it "inserts new keys and deprecates old keys" do
      t1 = Time.parse("2020-01-01T12:00:00Z")
      t2 = Time.parse("2020-02-01T12:00:00Z")
      t3 = Time.parse("2020-03-01T12:00:00Z")
      t4 = Time.parse("2020-04-01T12:00:00Z")
      File.write(path, "s1\n\t\ns2\n\n \t\n")
      Timecop.freeze(t1) do
        described_class.import_namespace_keys(path)
      end
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "s1", modified_at: match_time(t1), deprecated: false, namespace: "strings"),
        have_attributes(key: "s2", modified_at: match_time(t1), deprecated: false),
      )

      File.write(path, "s1\ns2\ns3\n")
      Timecop.freeze(t2) do
        described_class.import_namespace_keys(path)
      end
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "s1", modified_at: match_time(t1), deprecated: false),
        have_attributes(key: "s2", modified_at: match_time(t1), deprecated: false),
        have_attributes(key: "s3", modified_at: match_time(t2), deprecated: false),
      )

      File.write(path, "s2\ns3")
      Timecop.freeze(t3) do
        described_class.import_namespace_keys(path)
      end
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "s1", modified_at: match_time(t3), deprecated: true),
        have_attributes(key: "s2", modified_at: match_time(t1), deprecated: false),
        have_attributes(key: "s3", modified_at: match_time(t2), deprecated: false),
      )

      File.write(path, "s3")
      Timecop.freeze(t4) do
        described_class.import_namespace_keys(path)
      end
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "s1", modified_at: match_time(t3), deprecated: true),
        have_attributes(key: "s2", modified_at: match_time(t4), deprecated: true),
        have_attributes(key: "s3", modified_at: match_time(t2), deprecated: false),
      )
    end

    it "can load the default namespace file" do
      k = described_class.load_keys_from_file(described_class.static_keys_base_file)
      expect(k).to include("errors.unhandled_error")
    end
  end
end
