# frozen_string_literal: true

require "sequel/annotate"

require "suma/spec_helpers/rake"
require "suma/tasks/annotate"

RSpec.describe Suma::Tasks::Annotate, :db, :redirect do
  include Suma::SpecHelpers::Rake

  describe "annotate" do
    it "calls annotate" do
      expect(Kernel).to receive(:`).with("git diff").and_return("")
      expect(Sequel::Annotate).to receive(:annotate).with(include("lib/suma/member.rb"), border: true)
      expect(described_class).to receive(:write_typedefs).with(be_a(Pathname), include("Auto-generated JSDoc"))
      expect(described_class).to receive(:write_typedefs).with(be_a(Pathname), include("Auto-generated JSDoc"))
      invoke_rake_task("annotate")
      expect($stdout.string).to include("Finished annotating")
    end

    it "errors if git diff is not blank" do
      expect(Kernel).to receive(:`).with("git diff").and_return("xyz")
      expect(Kernel).to receive(:exit).with(1)
      invoke_rake_task("annotate")
      expect($stdout.string).to include("Cannot annotate while there")
    end
  end

  describe "write_typedefs" do
    it "calls write" do
      x = Pathname("foo")
      s = "abc"
      expect(File).to receive(:write).with(x, s)
      described_class.write_typedefs(x, s)
    end
  end
end
