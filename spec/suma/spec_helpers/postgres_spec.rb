# frozen_string_literal: true

require "rspec/matchers/fail_matchers"

require "suma/spec_helpers/postgres"

RSpec.describe Suma::SpecHelpers::Postgres, :db do
  include RSpec::Matchers::FailMatchers

  describe "have_row matcher" do
    let(:model) { Suma::Postgres::TestingPixie }

    before(:each) do
      model.create(name: "donna")
    end

    it "looks for a row with the given criteria" do
      expect(model).to have_row(name: "donna")

      expect do
        expect(model).to have_row(name: "ma")
      end.to fail_with(/Expected Suma::Postgres::TestingPixie to have a row matching criteria/)
    end

    it "matches found rows against attributes" do
      expect(model).to have_row(name: "donna").with_attributes(id: be_an(Integer))

      expect do
        expect(model).to have_row(name: "donna").with_attributes(id: be_an(String))
      end.to fail_with(/Row found but matcher failed with:/)
    end

    it "can be negated" do
      expect(model).to_not have_row(name: "NOT DONNA")

      expect do
        expect(model).to_not have_row(name: "donna")
      end.to fail_with(/to not have a row matching criteria/)

      expect do
        expect(model).to_not have_row(name: "donna").with_attributes(id: be_an(Integer))
      end.to fail_with(/to not have a row matching criteria/)
    end
  end

  describe "have_same_ids_as matcher" do
    def item(id, pk: :id)
      return [double(pk => id), {pk => id}, {pk.to_s => id}].sample
    end

    def collection
      return Array.new(5) { |i| item(i) }
    end

    it "matches collects with the same IDs in whatever order" do
      expect(collection.shuffle).to have_same_ids_as(collection.shuffle)
    end

    it "fails if collections are not of the same length" do
      expect do
        expect(collection + [item(6)]).to have_same_ids_as(collection)
      end.to fail_with(/expected ids/)
    end

    it "can use variadic expected" do
      item1 = item(1)
      item2 = item(2)
      expect([item1, item2]).to have_same_ids_as(item1, item2)
    end

    it "can use a custom pk field" do
      item1 = item(1, pk: :myid)
      item2 = item(2, pk: :myid)
      expect([item1, item2]).to have_same_ids_as(item1, item2).pk_field(:myid)
    end
  end

  describe "be_destroyed matcher" do
    it "succeeds if the model does not exist" do
      px = Suma::Postgres::TestingPixie.create
      px.destroy
      expect(px).to be_destroyed
    end

    it "fails if the model exists" do
      px = Suma::Postgres::TestingPixie.create
      expect do
        expect(px).to be_destroyed
      end.to fail_with(/did not expect to find item with id/)
    end
  end

  describe "be_bool matcher" do
    it "succeeds if expected is a bool" do
      expect(true).to be_bool
      expect(false).to be_bool
    end

    it "fails if expected is not a bool" do
      expect do
        expect(0).to be_bool
      end.to fail_with("0 must be true or false")
      expect do
        expect(1).to be_bool
      end.to fail_with("1 must be true or false")
      expect do
        expect(nil).to be_bool
      end.to fail_with("nil must be true or false")
      expect do
        expect("").to be_bool
      end.to fail_with('"" must be true or false')
    end
  end

  describe "check_transaction" do
    let(:db) { Suma::Postgres::TestingPixie.db }

    it "fails if in a transaction" do
      db.transaction do
        expect do
          Suma::Postgres.check_transaction(db, "")
        end.to raise_error(Suma::Postgres::InTransaction)
      end
    end

    it "can disable the transaction check", :no_transaction_check do
      db.transaction do
        expect do
          Suma::Postgres.check_transaction(db, "")
        end.to_not raise_error
      end
    end
  end
end
