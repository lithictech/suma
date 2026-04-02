# frozen_string_literal: true

require "sequel/identity_set"

RSpec.describe Sequel::IdentitySet do
  before(:all) do
    @db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    @db.drop_table?(:tester)
    @db.create_table(:tester) do
      primary_key :id
    end
  end

  let(:db) { @db }

  let(:cls) do
    Class.new(Sequel::Model(:tester)) do
      unrestrict_primary_key
    end
  end

  it "can do set operations" do
    o1 = cls.new(id: 1)
    o2 = cls.new(id: 2)
    s1 = described_class.new
    s1 << cls.new(id: 1)
    s1.add(o1)
    expect(s1.to_a).to contain_exactly(be === o1)
    expect(s1).to include(o1)
    expect(s1).to_not include(o2)
    expect(s1.to_s).to eq("Sequel::IdentitySet{[#< @values={id: 1}>]}")
    expect(s1.inspect).to eq("Sequel::IdentitySet{[#< @values={id: 1}>]}")

    s2 = described_class.new
    s2 << cls.new(id: 2)
    expect(described_class.flatten(s1, s2).to_a).to contain_exactly(be === o1, be === o2)

    s1.merge!(s2)
    expect(s1).to include(o2)

    vals = []
    # rubocop:disable Style/HashEachMethods, Style/MapIntoArray
    s1.each { |_k, v| vals << v }
    # rubocop:enable Style/HashEachMethods, Style/MapIntoArray
    expect(vals).to have_length(2)
  end
end
