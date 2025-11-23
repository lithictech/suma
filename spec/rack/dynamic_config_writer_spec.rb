# frozen_string_literal: true

require "rack/dynamic_config_writer"

RSpec.describe Rack::DynamicConfigWriter do
  include_context "uses temp dir"

  let(:index) { (temp_dir_path + "index.html").to_s }

  it "sets the config using default parameters" do
    File.write(index, "<html><head></head></html>")
    described_class.new(index).emplace({"x" => "1"})
    html = "<html><head><script>window.rackDynamicConfig={\"x\":\"1\"}</script></head><body></body></html>"
    expect(File.read(index)).to eq(html)
  end

  it "sets the config using passed parameters" do
    File.write(index, "<html><head>\n<meta />\n\n</head></html>")
    described_class.new(index, global_assign: "globals.x").emplace({"x" => "1"})
    expect(File.read(index)).to eq(
      "<html><head><script>globals.x={\"x\":\"1\"}</script>\n<meta>\n\n</head><body></body></html>",
    )
  end

  it "can run multiple times, using new parameters each time" do
    File.write(index, "<html><head></head></html>")
    dcw = described_class.new(index, global_assign: "globals.x")
    dcw.emplace({"x" => "1"})
    dcw.emplace({"x" => "2"})
    dcw.emplace({"x" => "3"})
    expect(File.read(index)).to eq("<html><head><script>globals.x={\"x\":\"3\"}</script></head><body></body></html>")
  end

  it "handles an empty document" do
    File.write(index, "")
    dcw = described_class.new(index, global_assign: "globals.x")
    dcw.emplace({"x" => "1"})
    dcw.emplace({"x" => "2"})
    dcw.emplace({"x" => "3"})
    expect(File.read(index)).to eq("<html><head><script>globals.x={\"x\":\"3\"}</script></head><body></body></html>")
  end

  it "handles a document with no head" do
    File.write(index, "<html><body></body></html>")
    dcw = described_class.new(index, global_assign: "globals.x")
    dcw.emplace({"x" => "1"})
    dcw.emplace({"x" => "2"})
    dcw.emplace({"x" => "3"})
    expect(File.read(index)).to eq("<html><head><script>globals.x={\"x\":\"3\"}</script></head><body></body></html>")
  end

  describe "with a manifest file" do
    let(:manifest) { (temp_dir_path + ".vite" + "manifest.json").to_s }
    before(:each) do
      Dir.mkdir(temp_dir_path + ".vite")
    end

    it "handles an empty manifest json" do
      File.write(index, "")
      File.write(manifest, "{}")

      dcw = described_class.new(index, global_assign: "globals.x")
      dcw.emplace({})
      expect(File.read(index)).to eq("<html><head><script>globals.x={}</script></head><body></body></html>")
    end
  end

  describe "pick_env" do
    let(:env) { {"FOO1" => "x1", "FOO2" => "x2", "BAR2" => "y2"} }
    it "picks keys with a prefix" do
      expect(described_class.pick_env("FOO", env)).to eq({"FOO1" => "x1", "FOO2" => "x2"})
    end

    it "picks keys matching a regex" do
      expect(described_class.pick_env(/2/, env)).to eq({"FOO2" => "x2", "BAR2" => "y2"})
    end
  end
end
