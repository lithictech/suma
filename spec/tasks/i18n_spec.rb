# frozen_string_literal: true

require "suma/spec_helpers/rake"
require "suma/tasks/i18n"

RSpec.describe Suma::Tasks::I18n, :db do
  include Suma::SpecHelpers::Rake

  describe "import" do
    it "imports seeds" do
      invoke_rake_task("i18n:import")
      expect(Suma::I18n::StaticString.dataset).to_not be_empty
    end
  end

  describe "export" do
    it "exports seeds" do
      # Just run the code
      expect { invoke_rake_task("i18n:export") }.to_not raise_error
    end
  end

  describe "replace" do
    it "replaces seeds" do
      invoke_rake_task("i18n:replace")
      expect(Suma::I18n::StaticString.dataset).to_not be_empty
    end
  end
end
