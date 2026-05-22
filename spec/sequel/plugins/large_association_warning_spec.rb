# frozen_string_literal: true

require "sequel/plugins/large_association_warning"

RSpec.describe Sequel::Plugins::LargeAssociationWarning, :db do
  before(:all) do
    @db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    @db.drop_table?(:largeassocwarn)
    @db.create_table(:largeassocwarn) do
      primary_key :id
      foreign_key :parent_id, :largeassocwarn
    end
  end
  after(:all) do
    @db.disconnect
  end

  it "undefines generated setters and skips their saving" do
    calls = []
    cls = Class.new(Sequel::Model(:largeassocwarn)) do
      plugin :large_association_warning, threshold: 5, callback: ->(*args) { calls << args }
      many_to_one :parent, class: self
      one_to_many :children, class: self, key: :parent_id
    end

    parent = cls.create
    Array.new(5) { cls.create(parent:) }
    parent.refresh.children
    expect(calls).to be_empty
    cls.create(parent:)
    expect(calls).to be_empty
    parent.refresh.children
    expect(calls).to contain_exactly([parent, :children, have_length(6)])
    # Do not re-warn
    parent.refresh.children
    expect(calls).to contain_exactly([parent, :children, have_length(6)])
  end

  it "copies configuration to subclasses" do
    base = Class.new(Sequel::Model(:largeassocwarn)) do
      plugin :large_association_warning, threshold: 5
    end
    sub = Class.new(base)

    expect(base.large_association_warning_threshold).to eq(5)
    expect(sub.large_association_warning_threshold).to eq(5)
  end
end
