# frozen_string_literal: true

require "tempfile"

require "suma"

RSpec.describe Suma do
  describe "load_fixture_data" do
    it "loads plain-text fixture data" do
      data = load_fixture_data("plain.txt")
      expect(data).to eq("Yep!\n")
    end

    it "loads JSON fixture data" do
      data = load_fixture_data("stuff.json")
      expect(data).to eq("here" => "is some JSON stuff")
    end

    it "loads YAML fixture data" do
      data = load_fixture_data("stuff.yml")
      expect(data).to eq("here" => "is some YAML stuff")
    end

    it "loads JSON fixture data without an extension" do
      data = load_fixture_data(:stuff)
      expect(data).to eq("here" => "is some JSON stuff")
    end

    it "falls back on YAML fixture data if there's no JSON file when loading without an extension" do
      data = load_fixture_data(:other_stuff)
      expect(data).to eq("here" => "is some other YAML stuff")
    end
  end

  describe "idempotency keys" do
    before do
      @bust_idem = described_class.bust_idempotency
      described_class.bust_idempotency = false
    end

    after do
      described_class.bust_idempotency = @bust_idem
    end

    it "is the same for the same model instance" do
      member = Suma::Member.new
      key1 = described_class.idempotency_key(member)
      key2 = described_class.idempotency_key(member)
      expect(key1).to eq(key2)
    end

    it "is the same for models with the same type and primary key" do
      member1 = Suma::Member.new
      member1.id = 1
      member2 = Suma::Member.new
      member2.id = 1

      key1 = described_class.idempotency_key(member1)
      key2 = described_class.idempotency_key(member2)
      expect(key1).to eq(key2)
    end

    it "is unique for the same model type with different ids" do
      member1 = Suma::Member.new
      member1.id = 1
      member2 = Suma::Member.new
      member2.id = 2

      key1 = described_class.idempotency_key(member1)
      key2 = described_class.idempotency_key(member2)
      expect(key1).not_to eq(key2)
    end

    it "is unique for model types" do
      member = Suma::Member.new
      person = Suma::Role.new

      memberkey = described_class.idempotency_key(member)
      personkey = described_class.idempotency_key(person)
      expect(memberkey).not_to eq(personkey)
    end

    it "is randomized if bust_idempotency is true" do
      described_class.bust_idempotency = true
      member = Suma::Member.new
      key1 = described_class.idempotency_key(member)
      key2 = described_class.idempotency_key(member)
      expect(key1).not_to eq(key2)
    end

    it "is unique when different `parts` are passed" do
      member = Suma::Member.new
      no_parts = described_class.idempotency_key(member)
      part_a = described_class.idempotency_key(member, "parta")
      part_b = described_class.idempotency_key(member, "partb")
      two_parts = described_class.idempotency_key(member, "part1", "part2")

      expect([no_parts, part_a, part_b, two_parts].uniq.count).to eq(4)
    end

    it "is unique on updated_at if updated_at is defined and not empty" do
      member = Suma::Member.new
      key1 = described_class.idempotency_key(member)
      member.updated_at = Time.now
      key2 = described_class.idempotency_key(member)
      expect(key1).not_to eq(key2)
    end

    it "is unique on created_at if updated_at is empty or undefined and created_at is defined" do
      member = Suma::Member.new
      member.created_at = Time.now - 1.second
      key1 = described_class.idempotency_key(member)
      member.created_at = Time.now
      key2 = described_class.idempotency_key(member)
      expect(key1).not_to eq(key2)
    end

    it "does not use created_at or updated_at if the model does not have it" do
      pixie = Suma::Postgres::TestingPixie.new
      pixie.id = 10
      key = described_class.idempotency_key(pixie)
      eq_key = described_class.idempotency_key(pixie)
      expect(key).to eq(eq_key)

      pixie.id = 11
      neq_key = described_class.idempotency_key(pixie)
      expect(key).not_to eq(neq_key)
    end
  end

  describe "request users" do
    it "can get and set the request user" do
      expect(Suma.request_user_and_admin).to eq([nil, nil])
      Suma.set_request_user_and_admin(1, 2)
      expect(Suma.request_user_and_admin).to eq([1, 2])
      expect(StateMachines::Sequel.current_actor).to eq(2)
      Suma.set_request_user_and_admin(nil, nil)
      expect(Suma.request_user_and_admin).to eq([nil, nil])
      expect(StateMachines::Sequel.current_actor).to eq(nil)
    end
    it "can set request user with a block" do
      expect(Suma.request_user_and_admin).to eq([nil, nil])
      Suma.set_request_user_and_admin(1, 2) do
        expect(Suma.request_user_and_admin).to eq([1, 2])
      end
      expect(Suma.request_user_and_admin).to eq([nil, nil])
    end
    it "errors when setting request user multiple times" do
      # this is okay
      Suma.set_request_user_and_admin(nil, nil)
      Suma.set_request_user_and_admin(nil, nil)
      # this will not be
      Suma.set_request_user_and_admin(1, 2)
      expect { Suma.set_request_user_and_admin(1, 2) }.to raise_error(Suma::InvalidPrecondition)
    ensure
      Suma.set_request_user_and_admin(nil, nil)
    end
  end

  describe "to_slug" do
    it "slugifies" do
      expect(described_class.to_slug("Alan's \"Farm\"")).to eq("alans_farm")
    end
  end

  describe "as_ary" do
    it "wraps non-arrays in an array" do
      expect(Suma.as_ary(1)).to eq([1])
      h = {}
      expect(Suma.as_ary(h)).to contain_exactly(be h)
      a = [1, 2, 3]
      expect(Suma.as_ary(a)).to be(a)
    end
  end

  describe "cached_get", reset_configuration: described_class do
    key = "k"
    before(:each) do
      @cnt = 0
      @cb = lambda do
        @cnt += 1
        "x"
      end
    end

    it "uses the cache if the key is present" do
      described_class.use_globals_cache = true
      expect(described_class.cached_get(key, &@cb)).to eq("x")
      expect(@cnt).to eq(1)
      expect(described_class.cached_get(key, &@cb)).to eq("x")
      expect(@cnt).to eq(1)
      described_class.cached_get("z", &@cb)
      expect(@cnt).to eq(2)
    end

    it "does not use the cache if not enabled" do
      described_class.use_globals_cache = false
      expect(described_class.cached_get(key, &@cb)).to eq("x")
      expect(@cnt).to eq(1)
      expect(described_class.cached_get(key, &@cb)).to eq("x")
      expect(@cnt).to eq(2)
      described_class.cached_get("z", &@cb)
      expect(@cnt).to eq(3)
    end

    it "can set/delete a key" do
      described_class.use_globals_cache = true
      described_class.cached_set(key, "x")
      expect(described_class.cached_get(key) { nil }).to eq("x")
      described_class.cached_set(key, nil, delete: true)
      expect(described_class.cached_get(key) { nil }).to be_nil
    end
  end

  describe "assert" do
    it "runs the block only in development or testing" do
      runs = 0
      incr = lambda do
        runs += 1
        true
      end
      Suma.assert(&incr)
      expect(runs).to eq(1)
      stub_const("Suma::RACK_ENV", "production")
      Suma.assert(&incr)
      expect(runs).to eq(1)
    end

    it "raises an assertion error if the block returns false" do
      expect do
        Suma.assert do
          false
        end
      end.to raise_error(Suma::AssertionError, "Assertion failed (block returned false)")

      expect do
        Suma.assert do
          [false, "my message"]
        end
      end.to raise_error(Suma::AssertionError, "my message")

      expect do
        Suma.assert do
          true
        end
      end.to_not raise_error

      expect do
        Suma.assert do
          [true, "my message"]
        end
      end.to_not raise_error
    end
  end
end
