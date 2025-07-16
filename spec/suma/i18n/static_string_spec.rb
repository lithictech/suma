# frozen_string_literal: true

RSpec.describe "Suma::I18n::StaticString", :db do
  let(:described_class) { Suma::I18n::StaticString }

  include_context "uses temp dir"

  describe "import_all_namespaces" do
    it "imports namespaces for all files present" do
      Dir.mkdir(temp_dir_path + "strings")
      File.write(temp_dir_path + "strings/ns1.txt", "s1")
      File.write(temp_dir_path + "strings/ns2.txt", "s2")
      described_class.import_all_namespaces(temp_dir_path + "strings")
      expect(described_class.all).to contain_exactly(
        have_attributes(key: "s1", namespace: "ns1"),
        have_attributes(key: "s2", namespace: "ns2"),
      )
    end
  end

  describe "import_namespace" do
    let(:path) { temp_dir_path + "strings.txt" }

    it "inserts new keys and deprecates old keys" do
      t1 = Time.parse("2020-01-01T12:00:00Z")
      t2 = Time.parse("2020-02-01T12:00:00Z")
      t3 = Time.parse("2020-03-01T12:00:00Z")
      t4 = Time.parse("2020-04-01T12:00:00Z")
      File.write(path, "s1\n\t\ns2\n\n \t\n")
      Timecop.freeze(t1) do
        described_class.import_namespace(path)
      end
      expect(described_class.all).to contain_exactly(
        have_attributes(key: "s1", modified_at: match_time(t1), deprecated: false, namespace: "strings"),
        have_attributes(key: "s2", modified_at: match_time(t1), deprecated: false),
      )

      File.write(path, "s1\ns2\ns3\n")
      Timecop.freeze(t2) do
        described_class.import_namespace(path)
      end
      expect(described_class.all).to contain_exactly(
        have_attributes(key: "s1", modified_at: match_time(t1), deprecated: false),
        have_attributes(key: "s2", modified_at: match_time(t1), deprecated: false),
        have_attributes(key: "s3", modified_at: match_time(t2), deprecated: false),
      )

      File.write(path, "s2\ns3")
      Timecop.freeze(t3) do
        described_class.import_namespace(path)
      end
      expect(described_class.all).to contain_exactly(
        have_attributes(key: "s1", modified_at: match_time(t3), deprecated: true),
        have_attributes(key: "s2", modified_at: match_time(t1), deprecated: false),
        have_attributes(key: "s3", modified_at: match_time(t2), deprecated: false),
      )

      File.write(path, "s3")
      Timecop.freeze(t4) do
        described_class.import_namespace(path)
      end
      expect(described_class.all).to contain_exactly(
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

  describe "Rebuilder" do
    describe "instance" do
      it "returns an instance" do
        expect(described_class::Rebuilder.instance).to be_a(described_class::Rebuilder)
      end
    end

    describe "start_watcher", reset_configuration: described_class do
      before(:each) do
        stub_const("Suma::I18n::StaticString::Rebuilder::SHUTDOWN_POLL_INTERVAL", 0.01)
      end

      after(:each) do
        Suma::Signals.reset
      end

      it "starts a watcher thread which rebuilds outdated" do
        Suma::I18n.static_string_rebuild_interval = 0
        r = described_class::Rebuilder.new
        calls = 0
        expect(r).to receive(:rebuild_outdated).twice do
          calls += 1
          Suma::Signals.handle_term if calls > 1
        end
        r.start_watcher
        r.join_watcher
      end

      it "errors if already started" do
        r = described_class::Rebuilder.new
        Suma::Signals.handle_term
        r.start_watcher
        expect { r.start_watcher }.to raise_error("already started")
        r.join_watcher
      end

      it "creates a listener that rebuilds files when notified", db: :no_transaction do
        r = described_class::Rebuilder.new
        r.start_watcher
        Suma::Fixtures.static_string.create(namespace: "n")
        path = r.path_for(locale: "en", namespace: "n")
        expect(path).to_not be_exist
        expect do
          # Must do this for each check, since the initial thread registration could miss the notify
          described_class.notify_change
          path
        end.to eventually(be_exist)
      ensure
        Suma::Signals.handle_term
        r.join_watcher
      end
    end

    describe "write_namespace" do
      it "writes an interpolated file for each static locale and the given namespace" do
        Suma::Fixtures.static_string.text("hi", es: "hola").create(namespace: "n1", key: "s1")
        Suma::Fixtures.static_string.text("hi").create(namespace: "n2", key: "s1")
        Suma::Fixtures.static_string.text("hi").create(namespace: "n3", key: "s1")

        described_class::Rebuilder.new(temp_dir_path).write_namespaces(["n1", "n2"])
        expect(File.read(temp_dir_path + "en_n1.json")).to eq('{"s1":["s","hi"]}')
        expect(File.read(temp_dir_path + "es_n1.json")).to eq('{"s1":["s","hola"]}')
        expect(Pathname(temp_dir_path + "en_n2.json")).to be_exist
        expect(Pathname(temp_dir_path + "en_n3.json")).to_not be_exist
      end
    end

    describe "rebuild_outdated" do
      it "rebuilds modified namespace files" do
        r = described_class::Rebuilder.new(temp_dir_path)
        s1 = Suma::Fixtures.static_string.text("hi").create(namespace: "n1", key: "s1")
        s2 = Suma::Fixtures.static_string.text("hi").create(namespace: "n2", key: "s2")

        r.rebuild_outdated
        old_n1_mtime = File.stat(temp_dir_path + "en_n1.json").mtime
        old_n2_mtime = File.stat(temp_dir_path + "en_n2.json").mtime

        s1.update(modified_at: Time.now)

        sleep(0.001)
        r.rebuild_outdated
        expect(File.stat(temp_dir_path + "en_n1.json").mtime).to be > old_n1_mtime
        expect(File.stat(temp_dir_path + "en_n2.json").mtime).to eq old_n2_mtime
      end
    end
  end
end
