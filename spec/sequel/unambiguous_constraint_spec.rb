# frozen_string_literal: true

require "sequel/unambiguous_constraint"

RSpec.describe "Sequel.unambiguous_cnstraint" do
  db = Sequel.connect("mock://")

  it "errors for no columns" do
    expect { Sequel.unambiguous_constraint([]) }.to raise_error(ArgumentError)
  end

  it "uses IS NOT NULL for one column" do
    c = Sequel.unambiguous_constraint([:x])
    expr = db[:tbl].where(c).sql
    expect(expr).to eq("SELECT * FROM tbl WHERE (x IS NOT NULL)")
  end

  it "uses null permutations for multiple columns" do
    c = Sequel.unambiguous_constraint([:x, :y, :z])
    expr = db[:tbl].where(c).sql
    expect(expr).to eq("SELECT * FROM tbl WHERE (" \
                       "((x IS NOT NULL) AND (y IS NULL) AND (z IS NULL)) OR " \
                       "((x IS NULL) AND (y IS NOT NULL) AND (z IS NULL)) OR " \
                       "((x IS NULL) AND (y IS NULL) AND (z IS NOT NULL)))")
  end

  it "can allow all columns to be null" do
    c = Sequel.unambiguous_constraint([:x, :y, :z], allow_all_null: true)
    expr = db[:tbl].where(c).sql
    expect(expr).to eq("SELECT * FROM tbl WHERE (" \
                       "((x IS NOT NULL) AND (y IS NULL) AND (z IS NULL)) OR " \
                       "((x IS NULL) AND (y IS NOT NULL) AND (z IS NULL)) OR " \
                       "((x IS NULL) AND (y IS NULL) AND (z IS NOT NULL)) OR " \
                       "((x IS NULL) AND (y IS NULL) AND (z IS NULL)))")
  end
end
