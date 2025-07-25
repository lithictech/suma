# frozen_string_literal: true

require "suma/postgres"

module SumaTestModels; end

RSpec.describe "Suma::Postgres::Model", :db do
  let(:described_class) { Suma::Postgres::Model }

  it "is abstract (doesn't have a dataset of its own)" do
    expect { described_class.dataset }.to raise_error(Sequel::Error, /no dataset/i)
  end

  it "has an array of db extensions" do
    expect(described_class.extensions).to include("citext")
  end

  context "a subclass" do
    it "gets the database connection when one is set on the parent" do
      subclass = create_model(:conn_setter)
      expect(described_class.db).to_not be_nil
      expect(subclass.db).to eq(described_class.db)
    end

    it "registers a topological dependency for associations" do
      subclass = create_model(:allergies)
      other_class = create_model(:food_preferences)
      other_class.many_to_one :related, class: subclass, key: :a_key

      sorted_classes = described_class.tsort
      expect(sorted_classes.index(subclass)).to be < sorted_classes.index(other_class)
    end

    it "doesn't register a dependency for an association marked as ':polymorphic'" do
      animal = create_model(:animals)
      ticket = create_model(:tickets)
      ticket.many_to_one :subject, class: animal, reciprocal: :tickets
      animal.one_to_many :tickets,
                         class: ticket,
                         key: :subject_id,
                         conditions: {subject_type: animal.name},
                         polymorphic: true

      # NameError: uninitialized constant Suma::Ticket
      expect { described_class.tsort }.to_not raise_error
    end
  end

  it "can create a schema even if it does exist" do
    expect(described_class).to_not be_schema_exists(:testing)
    described_class.create_schema(:testing)
    described_class.create_schema(:testing)
    expect(described_class).to be_schema_exists(:testing)
  end

  it "knows what its schema is named" do
    subclass = create_model([:testing, :a_table])
    expect(subclass.schema_name).to eq("testing")
    expect(Suma::Postgres::Model.all_loaded_schemas).to eq(["testing"])
  end

  it "knows that it doesn't belong to a schema if one hasn't been specified'" do
    subclass = create_model(:a_table)
    expect(subclass.schema_name).to eq(nil)
  end

  it "can build a single string of validation errors" do
    subclass = create_model(:the_constrained_table)

    obj = subclass.new
    obj.errors.add(:first_name, "is not present")
    obj.errors.add(:last_name, "is not present")
    obj.errors.add(:age, "is not an integer")

    expect(
      obj.error_messages,
    ).to eq("first_name is not present, last_name is not present, age is not an integer")
  end

  it "has a dataset to reduce expressions" do
    mc = Suma::Postgres::TestingPixie
    x = mc.create(name: "Pixie X")
    y = mc.create(name: "Pixie Y")
    z = mc.create(name: "Pixie Z")
    ds = mc.dataset.reduce_expr(:|, [nil, Sequel[name: "Pixie X"], Sequel[name: "Pixie Z"], nil])
    expect(ds.all).to have_same_ids_as(x, z)

    ds = mc.dataset.reduce_expr(:&, [false, Sequel[name: "Pixie X"], Sequel[name: "Pixie Z"], nil])
    expect(ds.all).to be_empty

    ds = mc.dataset.reduce_expr(:|, [false, Sequel[name: "Pixie X"], Sequel[name: "Pixie Z"], nil], method: :exclude)
    expect(ds.all).to have_same_ids_as(y)

    ds = mc.dataset
    expect(ds.reduce_expr(:|, [nil, false], method: :exclude)).to equal(ds)
  end

  it "knows named descendants" do
    desc = Suma::Postgres::Model.descendants.reject(&:anonymous?).map(&:name)
    expect(desc).to all(start_with("Suma::"))
  end

  describe "#find_or_create_or_find" do
    let(:model_class) { Suma::Postgres::TestingPixie }

    it "will find again if the create fails due to a race condition (UniqueConstraintViolation)" do
      name = "foo"
      placeholder = model_class.create(name: "not-" + name)
      expect(model_class).to receive(:find).with({name:}).twice do
        placeholder.name == name ? placeholder : nil
      end
      expect(model_class).to receive(:create).with({name:}) do
        placeholder.name = name
        raise Sequel::UniqueConstraintViolation
      end

      got = model_class.find_or_create_or_find(name:)
      expect(got).to_not be_nil
      expect(got).to be(placeholder)
    end

    it "can use a block with the call to create" do
      made = model_class.find_or_create_or_find(name: "foo") do |inst|
        inst.name = "bar"
      end
      expect(made.name).to eq("bar")
    end
  end

  describe "#find_or_new" do
    let(:model_class) { Suma::Postgres::TestingPixie }

    it "returns an instance matching criteria" do
      m = model_class.create(name: "x")
      expect(model_class.find_or_new(name: "x")).to be === m
    end

    it "calls the block and returns the instance" do
      m = model_class.find_or_new(name: "x") { |p| p.name = "y" }
      expect(m).to have_attributes(name: "y", id: nil)
    end

    it "handles no block given" do
      m = model_class.find_or_new(name: "x")
      expect(m).to have_attributes(name: "x", id: nil)
    end
  end

  describe "find!" do
    let(:model_class) { Suma::Postgres::TestingPixie }

    it "can error if an instance or dataset entry is not found" do
      expect do
        model_class.find!(name: "foo")
      end.to raise_error(Suma::InvalidPostcondition, 'No row matching Suma::Postgres::TestingPixie[{:name=>"foo"}]')

      expect do
        model_class.dataset.where(name: "foo").find!
      end.to raise_error(Suma::InvalidPostcondition, "No matching dataset row (params: {})")

      x = model_class.create(name: "foo")
      expect(model_class.find!(name: "foo")).to be === x
      expect(model_class.dataset.where(name: "foo").find!).to be === x
    end
  end

  context "async events", :async, db: :no_transaction do
    let(:instance) { Suma::Postgres::TestingPixie.new }

    it "can immediately send an event prefixed with the sending model object" do
      instance.db.transaction do
        expect do
          instance.publish_immediate("wuz", 18)
        end.to publish("suma.postgres.testingpixie.wuz", [18])
      end
    end

    it "can send an deferred event prefixed with the sending model object" do
      expect do
        instance.db.transaction do
          expect do
            instance.publish_deferred("deferred", "eighteen")
          end.to_not publish
        end
      end.to publish("suma.postgres.testingpixie.deferred", ["eighteen"])
    end

    it "can immediately publish a deferred event if do_not_defer_events is set" do
      Suma::Postgres.do_not_defer_events = true
      instance.db.transaction do
        expect do
          instance.publish_deferred("deferred")
          Suma::Postgres.do_not_defer_events = false
        end.to publish("suma.postgres.testingpixie.deferred")
      end
    end

    it "publishes a created event" do
      expect do
        instance.save_changes
      end.to publish("suma.postgres.testingpixie.created", match([be_an(Integer), hash_including("id", "name")]))
    end

    it "publishes an updated event" do
      instance.set(name: "fire").save_changes
      expect do
        instance.update(name: "ice")
      end.to publish("suma.postgres.testingpixie.updated", [instance.id, {"name" => ["fire", "ice"]}])
    end

    it "publishes a destroyed event" do
      instance.save_changes
      expect do
        instance.destroy
      end.to publish("suma.postgres.testingpixie.destroyed", match_array([instance.id, include("id", "name")]))
    end

    it "uses the model pk" do
      subclass = create_model(:nonid_pk) do
        primary_key :mypk
      end
      instance = subclass.new
      expect do
        instance.save_changes
      end.to publish(
        /suma\.spechelpers\.postgres\.models\.testtablenonidpk\d+\.created/,
        match([be_an(Integer), hash_including("mypk")]),
      )
    end

    it "can publish pgrange fields" do
      t1 = Time.parse("2011-01-01T00:00:00Z")
      t2 = Time.parse("2012-01-01T00:00:00Z")
      matcher = publish("suma.postgres.testingpixie.created")
      pixie = nil
      expect do
        pixie = Suma::Postgres::TestingPixie.create(active_during: t1..t2)
        pixie.save_changes
        pixie.active_during = Float::INFINITY
        pixie.save_changes
        pixie.destroy
      end.to matcher
      expect(pixie).to_not be_nil
      expect(matcher.recorded_events[0].payload).to match_array(
        [pixie.id, include("active_during" => "[2011-01-01 00:00:00.000000+0000,2012-01-01 00:00:00.000000+0000)")],
      )
      expect(matcher.recorded_events[1].payload).to match_array(
        [pixie.id, {"active_during" => ["[2011-01-01 00:00:00.000000+0000,2012-01-01 00:00:00.000000+0000)", "[,]"]}],
      )
      expect(matcher.recorded_events[2].payload).to match_array(
        [pixie.id, include("active_during" => "[,]")],
      )
    end

    it "does not publish duplicate or redundant events" do
      matcher = publish("suma.postgres.testingpixie.created")
      expect do
        instance.save_changes
        instance.update(name: "stone")
        instance.destroy
      end.to matcher
      expect(matcher.recorded_events.map(&:name)).to eq(
        [
          "suma.postgres.testingpixie.created",
          "suma.postgres.testingpixie.updated",
          "suma.postgres.testingpixie.destroyed",
        ],
      )
    end
  end

  describe "inspect" do
    it "uses symbol representation" do
      expect(Suma::Role.create(name: "sam").inspect).to include(' name: "sam"')
    end

    it "formats timestamps in the local timezone" do
      inst = Suma::Fixtures.member.create
      inst.created_at = Time.new(2016, 12, 30, 22, 17, 55, "-00:00")
      s = Time.use_zone(ActiveSupport::TimeZone.new("Hawaii")) do
        inst.inspect
      end
      expect(s).to include("created_at: 2016-12-30 12:17:55")
    end

    it "omits empty fields" do
      inst = Suma::Role.create(name: "foo")
      expect(inst.inspect).to include("name: ")
      inst.name = ""
      expect(inst.inspect).to_not include("name: ")
    end

    it "formats time ranges" do
      state = Suma::Postgres::TestingPixie.create
      state.active_during_begin = Time.new(2016, 12, 30, 22, 17, 55, "-00:00")
      state.active_during_end = Time.new(2017, 12, 30, 22, 17, 55, "-00:00")

      s = Time.use_zone(ActiveSupport::TimeZone.new("Hawaii")) do
        state.inspect
      end
      expect(s).to include("active_during: [2016-12-30 12:17:55...2017-12-30 12:17:55)")
    end

    it "formats cents columns using money" do
      state = Suma::Postgres::TestingPixie.create
      state.price_per_unit_cents = 240
      expect(state.inspect).to include("price_per_unit: $2.40")
    end

    it "formats cents columns where there is no money accessor" do
      state = Suma::Postgres::TestingPixie.create
      state.price_per_unit_cents = 240
      state.instance_eval("undef :price_per_unit", __FILE__, __LINE__)
      expect(state.inspect).to include("price_per_unit_cents: 240")
    end

    it "decrypts strings and uris" do
      ba = Suma::Fixtures.bank_account.create(account_number: "123456789")
      expect(ba.inspect).to include('account_number: "123...789')
      ba.account_number = "postgres://user:pass@localhost:1234/db"
      expect(ba.inspect).to include('account_number: "postgres://*:*@localhost')
    end

    it "shows the embedding size" do
      m = Suma::Fixtures.member.create(search_embedding: nil)
      expect(m.inspect).to_not include("search_embedding")
      m.search_embedding = []
      expect(m.inspect).to include("search_embedding: vector(384)")
      m.search_embedding = [1, 2, 3]
      expect(m.inspect).to include("search_embedding: vector(384)")
    end
  end

  describe "resource_lock!" do
    let(:instance) { Suma::Fixtures.member.create(note: "hello") }
    let(:now) { Time.now }

    it "raises a LockFailed if updated_at changed before/after the lock" do
      expect(instance).to receive(:updated_at).twice do
        now - rand
      end
      expect { instance.resource_lock! { true } }.to raise_error(Suma::LockFailed)
    end

    it "calls the block if updated_at is not set" do
      expect(instance).to have_attributes(updated_at: nil)
      expect(instance.resource_lock!(&:note)).to eq(instance.note)
    end

    it "calls the block if updated_at has not changed" do
      instance.update(updated_at: now.change(usec: 0))
      expect(instance.resource_lock!(&:note)).to eq(instance.note)
    end

    it "touches updated_at after the block returns" do
      expect { instance.resource_lock! { true } }.to(change(instance, :updated_at))
    end

    it "ignores fractional microseconds since databases do not store that precision" do
      instance.update(note: instance.note + "prime")
      expect(instance.refresh.updated_at.nsec).to eq(instance.refresh.updated_at.usec * 1000)
      instance.updated_at = instance.updated_at.change(nsec: (instance.updated_at.usec * 1000) + 1)
      expect(instance.resource_lock!(&:note)).to eq(instance.note)
    end
  end

  describe "slow query logging" do
    before(:each) { @duration = described_class.db.log_warn_duration }

    after(:each) { described_class.db.log_warn_duration = @duration }

    it "logs slow queries with structure" do
      described_class.db.log_warn_duration = -1
      logs = capture_logs_from(described_class.logger, level: :warn, formatter: :json) do
        described_class.db.execute("SELECT 1=1")
      end
      expect(logs).to contain_exactly(
        include_json(
          message: eq("sequel_query"),
          duration_ms: be_within(1).of(1),
          context: {
            query: eq("SELECT 1=1"),
          },
        ),
      )
    end

    it "does not try to parse messages that are not slow query logs" do
      logs = capture_logs_from(described_class.logger, level: :warn, formatter: :json) do
        described_class.logger.warn "hello there SELECT 1=1"
      end
      expect(logs).to have_a_line_matching(/"message":"hello there SELECT 1=1"/)
    end
  end

  describe "each_cursor_page" do
    names = ["a", "b", "c", "d"]
    cls = Suma::Postgres::TestingPixie
    let(:ds) { cls.dataset }

    before(:each) do
      names.each { |n| cls.create(name: n) }
    end

    it "chunks pages and calls each item in the block" do
      result = []
      cls.each_cursor_page(page_size: 2) { |r| result << r.name }
      expect(result).to eq(names)
    end

    it "can order by a column" do
      result = []
      cls.each_cursor_page(page_size: 2, order: Sequel.desc(:name)) { |r| result << r.name }
      expect(result).to eq(names.reverse)
    end

    it "can order by multiple columns" do
      result = []
      cls.each_cursor_page(page_size: 2, order: [Sequel.desc(:name), :id]) { |r| result << r.name }
      expect(result).to eq(names.reverse)
    end

    it "can yield the full page rather than a row" do
      result = []
      cls.each_cursor_page(page_size: 3, yield_page: true) { |page| page.map(&:name).each { |n| result << n } }
      expect(result).to eq(names)
    end

    it "can perform an action on the returned values of each chunk" do
      clean_ds = ds.exclude(Sequel.like(:name, "%prime")) # Avoid re-selecting the stuff we just inserted
      clean_ds.each_cursor_page_action(page_size: 3, action: ds.method(:multi_insert)) do |tp|
        {name: tp.name + "prime"}
      end
      expect(ds.order(:id).all.map(&:name)).to eq(
        ["a", "b", "c", "d", "aprime", "bprime", "cprime", "dprime"],
      )
    end

    it "can handle multiple return rows" do
      action_calls = 0
      action = lambda { |v|
        action_calls += 1
        ds.multi_insert(v)
      }
      cls.each_cursor_page_action(page_size: 3, action:) do |tp|
        tp.name == "a" ? (Array.new(10) { |i| {name: "a#{i}"} }) : nil
      end
      expect(ds.order(:id).all.map(&:name)).to eq(
        ["a", "b", "c", "d", "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9"],
      )
      expect(action_calls).to eq(2)
    end

    it "ignores nil results returned from the block" do
      cls.each_cursor_page_action(page_size: 1, action: ds.method(:multi_insert)) do |tp|
        tp.name >= "c" ? nil : {name: tp.name + "prime"}
      end
      expect(ds.order(:id).all.map(&:name)).to eq(
        ["a", "b", "c", "d", "aprime", "bprime"],
      )
    end
  end

  describe "one_to_many" do
    Suma::Postgres::Model.descendants.reject(&:anonymous?).each do |host_class|
      describe host_class.name do
        host_class.associations.each do |assoc_name|
          assoc = host_class.association_reflections.fetch(assoc_name)
          # We only care about reverse FKs on one-to-many
          next unless assoc.fetch(:type) == :one_to_many
          # Don't assume these are simple lookups
          next if assoc.fetch(:eager_block)
          describe "#{assoc_name} association" do
            fk_to_this_model = assoc.fetch(:key_method)
            assoc_class = Kernel.const_get(assoc.fetch(:class_name))
            assoc_table = [assoc_class.schema_name, assoc_class.table_name].compact.join(".")
            it "has an index on #{assoc_table}.#{fk_to_this_model}" do
              find_idx_sql = <<~SQL
                select
                  t.relname as table_name,
                  i.relname as index_name,
                  a.attname as column_name
                from
                  pg_class t,
                  pg_class i,
                  pg_index ix,
                  pg_attribute a
                where
                  t.oid = ix.indrelid
                and i.oid = ix.indexrelid
                and a.attrelid = t.oid
                and a.attnum = ANY(ix.indkey)
                and t.relkind = 'r'
                and t.oid::regclass = to_regclass('#{assoc_table}')
                and a.attname = '#{fk_to_this_model}'
              SQL
              rows = assoc_class.db.fetch(Sequel.lit(find_idx_sql)).all
              expect(rows).to be_present, "expected index on :#{assoc_table}, :#{fk_to_this_model}"
            end
          end
        end
      end
    end
  end
end
