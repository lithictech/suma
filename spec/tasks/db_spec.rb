# frozen_string_literal: true

require "suma/spec_helpers/rake"
require "suma/tasks/db"

RSpec.describe Suma::Tasks::DB do
  include Suma::SpecHelpers::Rake

  describe "drop_tables" do
    it "drops all tables" do
      expect(described_class).to receive(:exec).
        with(be_a(Sequel::Database), match(/DROP TABLE [\w.]+ CASCADE/)).
        at_least(10).times
      invoke_rake_task("db:drop_tables")
    end
  end

  describe "wipe" do
    it "truncates tables", db: :no_transaction do
      Suma::Fixtures.member.create
      # Speed this up since truncate cascade on many tables is slow
      expect(Suma::Postgres).to receive(:each_model_class) do |&b|
        b.call Suma::Member
      end
      invoke_rake_task("db:wipe")
      expect(Suma::Member.all).to be_empty
    end
  end

  describe "migrate" do
    it "runs the migrator" do
      expect(Suma::Postgres).to receive(:run_all_migrations).with(target: nil)
      invoke_rake_task("db:migrate")
    end

    it "can set a version" do
      expect(Suma::Postgres).to receive(:run_all_migrations).with(target: 5)
      invoke_rake_task("db:migrate", "5")
    end
  end

  describe "exec" do
    it "prints and runs" do
      cls = Class.new do
        attr_accessor :executed

        def execute(cmd) = @executed = cmd
      end
      db = cls.new
      expect(Kernel).to receive(:print).with("SELECT 1")
      expect(Kernel).to receive(:print).with("\n")
      described_class.exec(db, "SELECT 1")
      expect(db.executed).to eq("SELECT 1")
    end

    it "prints an error" do
      cls = Class.new do
        def execute(*) = raise "hi"
      end
      db = cls.new
      expect(Kernel).to receive(:print).with("SELECT 1")
      expect(Kernel).to receive(:print).with(" (error)\n")
      expect { described_class.exec(db, "SELECT 1") }.to raise_error("hi")
    end
  end
end
