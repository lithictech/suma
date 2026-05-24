# frozen_string_literal: true

require "sequel/plugins/efficient_each"

RSpec.describe Sequel::Plugins::EfficientEach, :db do
  before(:all) do
    @db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    @db.drop_table?(:efeach)
    @db.create_table(:efeach) do
      primary_key :id
      text :name
      foreign_key :parent_id, :efeach
    end
  end
  after(:all) do
    @db.disconnect
  end

  let(:cls) do
    Class.new(Sequel::Model(:efeach)) do
      plugin :efficient_each, page_size: 2
      many_to_one :parent, class: self
      one_to_many :children, class: self, key: :parent_id
    end
  end

  it "errors for an unknown association" do
    n = cls.create
    expect { n.efficient_each(:foo).first }.to raise_error(described_class::UnknownAssociation)
  end

  it "copies configuration to subclasses" do
    sub = Class.new(cls)

    expect(cls.efficient_each_page_size).to eq(2)
    expect(sub.efficient_each_page_size).to eq(2)
  end

  it "can work with a block or return an enumerator" do
    parent = cls.create
    ch = cls.create(parent:)
    expect(parent.children).to contain_exactly(ch)

    expect(parent.efficient_each(:children).to_a).to contain_exactly(ch)

    calls = []
    parent.efficient_each(:children) { |r| calls << r }
    expect(calls).to contain_exactly(ch)
  end

  describe "with a loaded association" do
    let(:parent) { cls.create }
    let!(:children) { Array.new(3) { cls.create(parent:) } }
    before(:each) do
      parent.associations[:children] = children
    end

    it "yields each item in the dataset" do
      got = parent.efficient_each(:children).to_a
      expect(got).to eq(children)
    end
  end

  describe "without a loaded association" do
    let(:parent) { cls.create }
    let!(:children) { Array.new(3) { cls.create(parent:) } }
    before(:each) do
      parent.refresh
    end

    it "streams pages from the dataset" do
      got = parent.efficient_each(:children).to_a
      expect(got).to contain_exactly(be === children[0], be === children[1], be === children[2])
    end

    it "stores the association if there is only one page" do
      children[2].destroy
      got = parent.efficient_each(:children).to_a
      expect(got).to contain_exactly(be === children[0], be === children[1])
      expect(parent.associations).to include(children: have_length(2))
    end

    it "handles an empty association array" do
      children.each(&:destroy)
      got = parent.efficient_each(:children).to_a
      expect(got).to be_empty
      expect(parent.associations).to include(children: [])
    end

    it "does not store the association if there is more than one page" do
      got = parent.efficient_each(:children).to_a
      expect(got).to contain_exactly(be === children[0], be === children[1], be === children[2])
      expect(parent.associations).to be_empty
    end
  end

  describe "dataset method each_cursor_page" do
    names = ["a", "b", "c", "d"]
    let(:ds) { cls.dataset }

    before(:each) do
      names.each { |n| cls.create(name: n) }
    end

    it "yields each item to the block" do
      result = []
      cls.dataset.each_cursor_page { |r| result << r.name }
      expect(result).to eq(names)
    end

    it "can order by a column" do
      result = []
      cls.dataset.each_cursor_page(order: Sequel.desc(:name)) { |r| result << r.name }
      expect(result).to eq(names.reverse)
    end

    it "can order by multiple columns" do
      result = []
      cls.dataset.each_cursor_page(order: [Sequel.desc(:name), :id]) { |r| result << r.name }
      expect(result).to eq(names.reverse)
    end

    it "can yield the full page rather than a row" do
      result = []
      cls.dataset.each_cursor_page(yield_page: true) { |page| result << page.map(&:name) }
      expect(result).to eq([["a", "b"], ["c", "d"]])
    end

    it "can use an override page size" do
      result = []
      cls.dataset.each_cursor_page(yield_page: true, page_size: 4) { |page| result << page.map(&:name) }
      expect(result).to eq([["a", "b", "c", "d"]])
    end
  end
end
