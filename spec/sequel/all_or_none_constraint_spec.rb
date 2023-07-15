# frozen_string_literal: true

require "sequel/all_or_none_constraint"

RSpec.describe "Sequel.all_or_none_constraint" do
  db = Sequel.connect("mock://")

  it "generates the correct sql" do
    c = Sequel.all_or_none_constraint([:x, :y])
    expr = db[:tbl].where(c).sql
    expect(expr).to eq(
      "SELECT * FROM tbl WHERE (((x IS NULL) AND (y IS NULL)) OR ((x IS NOT NULL) AND (y IS NOT NULL)))",
    )
  end
end
