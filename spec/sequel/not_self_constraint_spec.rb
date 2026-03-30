# frozen_string_literal: true

require "sequel/not_self_constraint"

RSpec.describe "Sequel.not_self_constraint" do
  db = Sequel.connect("mock://")

  it "generates the correct sql" do
    c = Sequel.not_self_constraint(:x)
    expr = db[:tbl].where(c).sql
    expect(expr).to eq("SELECT * FROM tbl WHERE ((x IS NULL) OR (x != id))")
  end
end
