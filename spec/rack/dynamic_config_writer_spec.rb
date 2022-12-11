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
end
