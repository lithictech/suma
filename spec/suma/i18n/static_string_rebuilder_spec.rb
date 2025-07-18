# frozen_string_literal: true

require "suma/i18n/static_string_rebuilder"

RSpec.describe Suma::I18n::StaticStringRebuilder, :db do
  include_context "uses temp dir"

  describe "instance" do
    it "returns an instance" do
      expect(described_class.instance).to be_a(described_class)
    end
  end

  describe "start_watcher", reset_configuration: Suma::I18n do
    before(:each) do
      stub_const("Suma::I18n::StaticStringRebuilder::SHUTDOWN_POLL_INTERVAL", 0.01)
    end

    after(:each) do
      Suma::Signals.reset
    end

    it "starts a watcher thread which rebuilds outdated" do
      Suma::I18n.static_string_rebuild_interval = 0
      r = described_class.new
      calls = 0
      expect(r).to receive(:rebuild_outdated).twice do
        calls += 1
        Suma::Signals.handle_term if calls > 1
      end
      r.start_watcher
      r.join_watcher
    end

    it "errors if already started" do
      r = described_class.new
      Suma::Signals.handle_term
      r.start_watcher
      expect { r.start_watcher }.to raise_error("already started")
      r.join_watcher
    end

    it "creates a listener that rebuilds files when notified", db: :no_transaction do
      r = described_class.new
      r.start_watcher
      Suma::Fixtures.static_string.create(namespace: "n")
      path = r.path_for(locale: "en", namespace: "n")
      expect(path).to_not be_exist
      expect do
        # Must do this for each check, since the initial thread registration could miss the notify
        described_class.notify_change
        path
      end.to eventually(be_exist).within(5)
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

      described_class.new(temp_dir_path).write_namespaces(["n1", "n2"])
      expect(File.read(temp_dir_path + "en_n1.json")).to eq('{"s1":["s","hi"]}')
      expect(File.read(temp_dir_path + "es_n1.json")).to eq('{"s1":["s","hola"]}')
      expect(Pathname(temp_dir_path + "en_n2.json")).to be_exist
      expect(Pathname(temp_dir_path + "en_n3.json")).to_not be_exist
    end
  end

  describe "rebuild_outdated" do
    it "rebuilds modified namespace files" do
      r = described_class.new(temp_dir_path)
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
