# frozen_string_literal: true

require "suma/tasks/i18n"

RSpec.describe Suma::Tasks::I18n, :db do
  before(:all) do
    described_class.new
  end

  describe "import" do
    it "imports seeds" do
      Rake::Task["i18n:import"].invoke
      expect(Suma::I18n::StaticString.dataset).to_not be_empty
    end
  end

  describe "export" do
    it "exports seeds" do
      # Just run the code
      expect { Rake::Task["i18n:export"].invoke }.to_not raise_error
    end
  end

  describe "replace" do
    it "replaces seeds" do
      Rake::Task["i18n:replace"].invoke
      expect(Suma::I18n::StaticString.dataset).to_not be_empty
    end
  end
end
