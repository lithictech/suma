# frozen_string_literal: true

require "sequel/null_or_present_constraint"

RSpec.describe "Sequel.null_or_present_constraint" do
  db = Sequel.connect("mock://")

  it "generates the correct sql" do
    c = Sequel.null_or_present_constraint(:x)
    expr = db[:tbl].where(c).sql
    expect(expr).to eq("SELECT * FROM tbl WHERE ((x IS NULL) OR (x != ''))")
  end
end
