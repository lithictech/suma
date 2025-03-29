# frozen_string_literal: true

require "sequel/plugins/association_array_replacer"

RSpec.describe Sequel::Plugins::AssociationArrayReplacer, :db do
  before(:all) do
    @db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    @db.drop_table?(:arrayreplacertest)
    @db.create_table(:arrayreplacertest) do
      primary_key :id
      foreign_key :parent_id, :arrayreplacertest
    end
  end
  after(:all) do
    @db.disconnect
  end

  describe "configuration" do
    it "errors if the pks plugin is not loaded" do
      expect do
        Class.new(Sequel::Model(:arrayreplacertest)) do
          one_to_many :others, key: :parent_id, class: self
          plugin :association_array_replacer, :others
        end
      end.to raise_error(Sequel::Error, "model must have loaded `plugin :association_pks` first")
    end

    it "errors for an invalid association" do
      expect do
        Class.new(Sequel::Model(:arrayreplacertest)) do
          plugin :association_pks
          plugin :association_array_replacer, :others
        end
      end.to raise_error(Sequel::Error, "others is not a valid association")
    end
  end

  it "allows replacement of an _to_many array" do
    cls = Class.new(Sequel::Model(:arrayreplacertest)) do
      plugin :association_pks
      one_to_many :others, key: :parent_id, class: self
      plugin :association_array_replacer, :others
    end

    item = cls.create
    other1 = cls.create
    other2 = cls.create
    other3 = cls.create
    item.add_other(other1)
    expect(item.others).to contain_exactly(be === other1)
    item.replace_others([other2, other3])
    expect(item.others).to contain_exactly(be === other2, other3)
    item.replace_others([])
    expect(item.others).to be_empty
  end
end
