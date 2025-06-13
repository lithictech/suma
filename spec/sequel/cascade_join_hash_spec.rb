# frozen_string_literal: true

require "sequel/cascade_join_hash"

RSpec.describe "Sequel.cascade_join_hash" do
  it "generates the correct sql" do
    c = Sequel.cascade_join_hash({foo_id: :foos, bar_id: :bars})
    expect(c).to eq(
      {
        bar_id: {on_delete: :cascade, table: :bars},
        foo_id: {on_delete: :cascade, table: :foos},
      },
    )
  end
end
