# frozen_string_literal: true

require "rack/index_templater"

RSpec.describe Rack::IndexTemplater do
  include_context "uses temp dir"

  let(:index) { (temp_dir_path + "index.html").to_s }

  it "formats the index as an ERB template using the passed hash" do
    File.write(index, "<html><%= x %></html>")
    described_class.new(index).emplace({"x" => "1"})
    expect(File.read(index)).to eq("<html>1</html>")
  end

  it "can run multiple times, using new parameters each time" do
    File.write(index, "<html><%= x %></html>")
    dcw = described_class.new(index)
    dcw.emplace({"x" => "1"})
    dcw.emplace({"x" => "2"})
    dcw.emplace({"x" => "3"})
    expect(File.read(index)).to eq("<html>3</html>")
  end
end
