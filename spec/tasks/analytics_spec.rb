# frozen_string_literal: true

require "suma/spec_helpers/rake"
require "suma/tasks/analytics"

RSpec.describe Suma::Tasks::Analytics, :db do
  include Suma::SpecHelpers::Rake

  describe "truncate" do
    it "deletes analytics tables" do
      Suma::Analytics::Member.create(member_id: 1)
      invoke_rake_task("analytics:truncate")
      expect(Suma::Analytics::Member.all).to be_empty
    end
  end

  describe "import" do
    it "imports tables" do
      expect(Suma::Analytics::Member.all).to be_empty
      Suma::Fixtures.member.create
      invoke_rake_task("analytics:import")
      expect(Suma::Analytics::Member.all).to have_length(1)
    end
  end
end
