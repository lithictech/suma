# frozen_string_literal: true

require "sequel/plugins/association_deleter"

RSpec.describe Sequel::Plugins::AssociationDeleter, :db do
  before(:all) do
    @db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    @db.drop_table?(:test_items)
    @db.create_table(:test_items) do
      primary_key :id
      foreign_key :parent1_id, :test_items
      foreign_key :parent2_id, :test_items
    end
  end
  after(:all) do
    @db.disconnect
  end

  describe "plugin" do
    it "specifies associations to have a deleter" do
      cls = Class.new(Sequel::Model(:test_items)) do
        many_to_one :parent1, key: :parent1_id, class: self
        one_to_many :children1, key: :parent1_id, class: self

        many_to_one :parent2, key: :parent2_id, class: self
        one_to_many :children2, key: :parent2_id, class: self

        plugin :association_deleter, :children1
      end

      parent = cls.create
      children1_a = parent.add_children1({parent1: parent})
      children1_b = parent.add_children1({parent1: parent})
      children2_a = parent.add_children2({parent2: parent})
      children2_b = parent.add_children2({parent2: parent})

      expect(parent).to respond_to(:delete_all_children1)
      expect(parent).to_not respond_to(:delete_all_children2)

      parent.refresh
      expect(parent.children1).to contain_exactly(be === children1_a, be === children1_b)
      expect(parent.children2).to contain_exactly(be === children2_a, be === children2_b)

      parent.delete_all_children1

      expect(parent.associations[:children1]).to eq([]) # We want this to be cached because we know it's empty
      expect(parent.children1).to be_empty
      expect(parent.children2).to contain_exactly(be === children2_a, be === children2_b)
      parent.refresh
      expect(parent.children1).to be_empty
      expect(parent.children2).to contain_exactly(be === children2_a, be === children2_b)
    end

    it "can call the deleter method explicitly" do
      cls = Class.new(Sequel::Model(:test_items)) do
        many_to_one :parent1, key: :parent1_id, class: self
        one_to_many :children1, key: :parent1_id, class: self
        plugin :association_deleter
      end

      parent = cls.create
      children1_a = parent.add_children1({parent1: parent})
      children1_b = parent.add_children1({parent1: parent})

      expect(parent.children1).to contain_exactly(be === children1_a, be === children1_b)
      parent.delete_association(:children1)
      expect(parent.children1).to be_empty
      parent.refresh
      expect(parent.children1).to be_empty
    end

    it "errors if invalid associations are passed in" do
      expect do
        Class.new(Sequel::Model(:test_items)) do
          plugin :association_deleter, :not_an_assoc
        end
      end.to raise_error(Sequel::Error, /not_an_assoc is not a valid association/)

      expect do
        Class.new(Sequel::Model(:test_items)) do
          many_to_one :parent, key: :parent1_id, class: self
          plugin :association_deleter, :parent
        end
      end.to raise_error(Sequel::Error, /only be used for one_to_many/)
    end
  end
end
