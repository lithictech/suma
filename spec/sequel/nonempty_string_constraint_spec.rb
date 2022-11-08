# frozen_string_literal: true

require "sequel/nonempty_string_constraint"

RSpec.describe "Sequel.nonempty_string_constraint" do
  db = Sequel.connect("mock://")

  it "generates the correct sql" do
    c = Sequel.nonempty_string_constraint(:x)
    expr = db[:tbl].where(c).sql
    expect(expr).to eq("SELECT * FROM tbl WHERE ((x IS NOT NULL) AND (x != ''))")
  end
end
