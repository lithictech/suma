# frozen_string_literal: true

require "sequel/plugins/immutable"

RSpec.describe Sequel::Plugins::Immutable, :db do
  before(:all) do
    @db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    @db.drop_table?(:immutable_test_items)
    @db.create_table(:immutable_test_items) do
      primary_key :id
      text :name
    end
  end
  after(:all) do
    @db.disconnect
  end

  describe "plugin" do
    it "allows rows to be created and deleted but not updated" do
      cls = Class.new(Sequel::Model(:immutable_test_items)) do
        plugin :immutable
      end

      x = cls.create(name: "x")
      expect { x.update(name: "y") }.to raise_error(FrozenError)
      expect { x.name = "y" }.to_not raise_error

      y = cls[name: "x"]
      expect { y.name = "y" }.to_not raise_error
      expect { y.update(name: "y") }.to raise_error(FrozenError)

      z = cls.new
      z.name = "z"
      z.save_changes
      # rubocop:disable Sequel/SaveChanges
      expect { z.save }.to raise_error(FrozenError)
      # rubocop:enable Sequel/SaveChanges
    end

    it "can work with the dirty plugin" do
      cls = Class.new(Sequel::Model(:immutable_test_items)) do
        plugin :dirty
        plugin :immutable
      end

      x = cls.create(name: "x")
      expect { x.update(name: "y") }.to raise_error(FrozenError)
    end
  end
end
