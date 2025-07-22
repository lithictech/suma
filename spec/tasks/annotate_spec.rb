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
end
