# frozen_string_literal: true

RSpec.describe "Suma::Analytics::Model", :db do
  let(:described_class) { Suma::Analytics::Model }

  after(:each) do
    @models&.each(&:trash_class)
  end

  def analytics_model(name, &)
    m = create_model(name, model_class: Suma::Analytics::Model, &)
    (@models ||= []) << m
    return m
  end

  describe "#to_rows" do
    it "calls the handler (named) for the class and returns the row array" do
      subclass = analytics_model("ToRowsArray")
      subclass.instance_eval do
        unique_key :member_id
        denormalize Suma::Member, with: :denormalize_member
        def denormalize_member(m) = [{member_id: m.id, phone: m.phone}]
      end
      m = Suma::Fixtures.member.create(phone: "12223334444")
      expect(subclass.to_rows(m)).to eq([{member_id: m.id, phone: "12223334444"}])
    end

    it "calls the handler (anonymous) for the class and wraps a returned hash into a row array" do
      subclass = analytics_model("ToRowsHash")
      subclass.instance_eval do
        unique_key :member_id
        denormalize Suma::Member, with: ->(m) { {member_id: m.id, phone: m.phone} }
      end
      m = Suma::Fixtures.member.create(phone: "12223334444")
      expect(subclass.to_rows(m)).to eq([{member_id: m.id, phone: "12223334444"}])
    end

    it "calls the handler (shorthand) for the class" do
      subclass = analytics_model("HashHandler")
      subclass.instance_eval do
        unique_key :member_id
        denormalize Suma::Member, with: [
          [:member_id, :id],
          :phone,
          [:email, ->(m) { m.email.upcase }],
        ]
      end
      m = Suma::Fixtures.member.create(phone: "12223334444", email: "a@b.c")
      expect(subclass.to_rows(m)).to eq([{
                                          member_id: m.id,
                                          phone: "12223334444",
                                          email: "A@B.C",
                                        }])
    end

    it "errors for an invalid handler shorthand type" do
      subclass = analytics_model("HashHandler")
      subclass.instance_eval do
        unique_key :member_id
        denormalize Suma::Member, with: ["foo"]
      end
      expect do
        subclass.to_rows(Suma::Fixtures.member.create)
      end.to raise_error(/invalid denormalizer shorthand: "foo"/)
    end

    it "converts money into decimals" do
      subclass = analytics_model("MoneyModel") do
        decimal :amount
      end
      subclass.instance_eval do
        unique_key :member_id
        denormalize Suma::Member, with: [
          [:member_id, :id],
          [:amount, ->(*) { Money.new(111) }],
        ]
      end
      m = Suma::Fixtures.member.create
      expect(subclass.to_rows(m)).to eq([{
                                          member_id: m.id,
                                          amount: 1.11,
                                        }])
    end

    it "errors if a row does not include the unique key" do
      subclass = analytics_model("MissingUniqueKey")
      subclass.instance_eval do
        unique_key :member_id
        denormalize Suma::Member, with: ->(m) { {phone: m.phone} }
      end
      m = Suma::Fixtures.member.create
      expect { subclass.to_rows(m) }.to raise_error(/table's unique key :member_id/)
    end
  end

  describe "#destroy_rows" do
    it "deletes rows in the table using the specified class" do
      subclass = analytics_model("Destroy") do
        integer :member_id, unique: true
      end
      subclass.instance_eval do
        unique_key :member_id
        destroy_from Suma::Member
      end
      subclass.upsert_rows({member_id: 1}, {member_id: 2})
      subclass.destroy_rows(1)
      expect(subclass.all).to contain_exactly(include(member_id: 2))
      subclass.destroy_rows([2])
      expect(subclass.all).to be_empty
    end
  end

  describe "#upsert_rows" do
    it "noops if no rows" do
      subclass = analytics_model("InsertRows")
      subclass.upsert_rows
      expect(subclass.all).to be_empty
    end

    it "inserts rows" do
      subclass = analytics_model("InsertRows") do
        integer :member_id, unique: true
        text :name
      end
      subclass.instance_eval do
        unique_key :member_id
      end
      subclass.upsert_rows({member_id: 1, name: "hello"}, {member_id: 2, name: "bye"})
      expect(subclass.all).to contain_exactly(include(member_id: 1, name: "hello"), include(member_id: 2, name: "bye"))
    end

    it "updates rows" do
      subclass = analytics_model("InsertRows") do
        integer :member_id, unique: true
        text :name
      end
      subclass.instance_eval do
        unique_key :member_id
      end
      subclass.upsert_rows({member_id: 1, name: "hello"}, {member_id: 2, name: "bye"})
      expect(subclass.all).to contain_exactly(include(member_id: 1, name: "hello"), include(member_id: 2, name: "bye"))
      subclass.upsert_rows({member_id: 1, name: "hola"})
      expect(subclass.all).to contain_exactly(include(member_id: 1, name: "hola"), include(member_id: 2, name: "bye"))
    end

    it "errors if all hashes do not have the same keys" do
      subclass = analytics_model("InconsistentHashes") do
        integer :member_id, unique: true
      end
      subclass.instance_eval do
        unique_key :member_id
      end
      expect do
        subclass.upsert_rows({member_id: 1, name1: "hello"}, {member_id: 2, name2: "bye"})
      end.to raise_error(described_class::RowMismatch, /member_id=2 has the keys/)
    end

    describe "when multiple hashes have the same unique key" do
      it "combines them for insert/update" do
        subclass = analytics_model("SplitSchema") do
          integer :member_id, unique: true
          text :name1
          text :name2
        end
        subclass.instance_eval do
          unique_key :member_id
        end
        subclass.upsert_rows({member_id: 1, name1: "hi"}, {member_id: 1, name2: "hello"})
        expect(subclass.all).to contain_exactly(include(member_id: 1, name1: "hi", name2: "hello"))
        subclass.upsert_rows({member_id: 1, name1: "hi2"}, {member_id: 1, name2: "hello2"})
        expect(subclass.all).to contain_exactly(include(member_id: 1, name1: "hi2", name2: "hello2"))
      end

      it "errors if all hashes do not end up with the same schema" do
        subclass = analytics_model("InconsistentSchema") do
          integer :member_id, unique: true
        end
        subclass.instance_eval do
          unique_key :member_id
        end
        expect do
          subclass.upsert_rows(
            {member_id: 1, name1: "x"},
            {member_id: 1, name2: "x"},
            {member_id: 2, name1: "x"},
          )
        end.to raise_error(described_class::RowMismatch, /member_id=2 has the keys/)
      end
    end
  end
end
