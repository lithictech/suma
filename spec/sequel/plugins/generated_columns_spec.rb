# frozen_string_literal: true

require "sequel/plugins/generated_columns"

RSpec.describe Sequel::Plugins::GeneratedColumns, :db do
  before(:all) do
    @db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    @db.drop_table?(:gencoltest)
    @db.create_table(:gencoltest) do
      primary_key :id
      integer :intcol, default: 1
      integer :gencol, generated_always_as: Sequel[5]
    end
  end
  after(:all) do
    @db.disconnect
  end

  it "undefines generated setters and skips their saving" do
    cls = Class.new(Sequel::Model(:gencoltest)) do
      plugin :generated_columns
    end

    item = cls.create
    expect(item).to respond_to(:intcol)
    expect(item).to respond_to(:intcol=)
    expect(item).to respond_to(:gencol)
    expect(item).to_not respond_to(:gencol=)
    expect(item).to have_attributes(intcol: 1, gencol: 5)
    # rubocop:disable Sequel/SaveChanges
    expect { item.save }.to_not raise_error
    # rubocop:enable Sequel/SaveChanges
  end
end
