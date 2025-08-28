# frozen_string_literal: true

require "sequel/advisory_lock"

RSpec.describe Sequel::AdvisoryLock do
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

  let(:db) { @db }

  it "can convert a bigint key to and from int parts" do
    parts = described_class.key_to_parts(87_000_123_654)
    expect(parts).to eq([1_100_777_734, 20])
    expect(described_class.parts_to_key(*parts)).to eq(87_000_123_654)
  end

  it "can lock with a Long key" do
    lock = described_class.new(db, 6_000_123_654)
    expect(lock.dataset(this: true).all).to be_empty
    lock.with_lock do
      expect(lock.dataset(this: true).all).to have_attributes(size: 1)
    end
  end

  it "can lock with two Integer keys" do
    lock = described_class.new(db, 23_484, 284_220)
    expect(lock.dataset(this: true).all).to be_empty
    lock.with_lock do
      expect(lock.dataset(this: true).all).to have_attributes(size: 1)
    end
  end

  it "can lock and unlock" do
    lock = described_class.new(db, 6_000_123_654)
    expect(lock.lock).to be_truthy
    expect(lock.dataset(this: true).all).to have_attributes(size: 1)
    lock.unlock_all
    expect(lock.dataset(this: true).all).to be_empty
  end
end
