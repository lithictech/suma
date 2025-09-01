# frozen_string_literal: true

require "sequel"
require "sequel/sequel_hybrid_search"
require "sequel/sequel_hybrid_search/subproc_sentence_transformer_generator"
require "sequel/sequel_hybrid_search/api_embedding_generator"

RSpec.describe "sequel-hybrid-searchable" do
  fake_embeddings_generator = Class.new do
    DEFAULT_EMBEDDING = [0] * 384
    attr_accessor :model_name, :embedding

    def initialize(model_name: "fake", embedding: DEFAULT_EMBEDDING)
      @model_name = model_name
      @embedding = embedding
    end

    def get_embedding(*) = self.embedding
  end

  before(:all) do
    @db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    @db.drop_table?(:svs_tester)
    @db.create_table(:svs_tester) do
      primary_key :id
      text :name
      text :desc
      integer :parent_id
      timestamptz :created_at
      text :unrelated
      text :search_content
      column :search_embedding, Sequel.lit("vector(384)")
      text :search_hash
      index Sequel.function(:to_tsvector, "english", :search_content)
    end
    SequelHybridSearch.indexing_mode = :off
    @searchable = SequelHybridSearch.searchable_models.dup
  end

  after(:all) do
    @db.disconnect
    SequelHybridSearch.indexing_mode = :off
    SequelHybridSearch.embedding_generator = nil
  end

  before(:each) do
    @db[:svs_tester].truncate
    SequelHybridSearch.searchable_models.clear
    SequelHybridSearch.indexing_mode = :off
    # In most cases we don't need real embeddings, so use this for speed.
    SequelHybridSearch.embedding_generator = fake_embeddings_generator.new
  end

  after(:each) do
    SequelHybridSearch.searchable_models.replace(@searchable)
    # Must be reset in case a test shut it down.
    SequelHybridSearch.threadpool = nil
  end

  let(:model) do
    m = Class.new(Sequel::Model(:svs_tester)) do
      plugin :hybrid_search
      many_to_one :parent, class: self
      def hybrid_search_text
        return <<~TEXT
          This is a test model. It has the following fields:
          id: #{self.id}
          name: #{self.name}
          description: #{self.desc}
          created_at: #{self.created_at&.iso8601}
        TEXT
      end
    end
    m.dataset = @db[:svs_tester]
    m
  end

  describe "configuration" do
    it "errors for an invalid index mode" do
      expect do
        SequelHybridSearch.indexing_mode = :x
      end.to raise_error(/must be one of/)
    end

    it "can define custom options" do
      m = Class.new(Sequel::Model(:svs_tester)) do
        plugin :hybrid_search,
               content_column: :ccol,
               vector_column: :vcol,
               hash_column: :hcol
      end
      expect(m.hybrid_search_content_column).to eq(:ccol)
      expect(m.hybrid_search_vector_column).to eq(:vcol)
      expect(m.hybrid_search_hash_column).to eq(:hcol)
    end

    it "errors if hybrid_search_text is not defined" do
      m = Class.new(Sequel::Model(:svs_tester)) do
        plugin :hybrid_search
      end
      SequelHybridSearch.searchable_models.delete(m) # Don't leave this sitting around
      o = m.new
      expect { o.hybrid_search_text }.to raise_error(NoMethodError)
    end
  end

  it "indexes after save and can search" do
    geralt = model.create(name: "Geralt", desc: "Rivia")
    ciri = model.create(name: "Rivia", desc: "Ciri")
    model.hybrid_search_reindex_all

    expect(model.dataset.hybrid_search("tester").all).to have_same_ids_as(geralt, ciri)
  end

  describe "search" do
    before(:each) do
      # We need real embeddings to test search
      SequelHybridSearch.embedding_generator = SequelHybridSearch::SubprocSentenceTransformerGenerator
    end

    it "performs a hybrid semantic and keyword search" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      ciri = model.create(name: "Rivia", desc: "Ciri")
      model.hybrid_search_reindex_all

      got = model.dataset.hybrid_search("test models named 'geralt'").first
      expect(got).to be_a(model)
      expect(got).to have_attributes(id: geralt.id, name: "Geralt")
    end

    it "chains from the underlying dataset" do
      model.create(name: "Geralt", desc: "Rivia")
      model.create(name: "Rivia", desc: "Ciri")
      model.hybrid_search_reindex_all
      expect(model.dataset.exclude(name: "Geralt").hybrid_search("test models named 'geralt'")).to be_empty
    end

    it "errors if the model has no primary key" do
      model.instance_eval do
        def self.primary_key = nil
      end

      expect { model.dataset.hybrid_search("hi") }.to raise_error(/must have a primary key/)
    end

    it "only includes results matching the keyword search" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      ciri = model.create(name: "Rivia", desc: "Ciri")
      model.hybrid_search_reindex_all

      got = model.dataset.hybrid_search("geralt").all
      expect(got).to have_same_ids_as(geralt)
    end

    it "handles an empty search result" do
      expect(model.dataset.hybrid_search("matchnothing").all).to be_empty
      model.create(name: "Geralt", desc: "Rivia")
      model.hybrid_search_reindex_all
      expect(model.dataset.hybrid_search("matchnothing").all).to be_empty
    end

    it "returns all results on empty or asterik" do
      geralt = model.create(name: "Geralt")
      ciri = model.create(name: "Ciri")
      model.hybrid_search_reindex_all

      got = model.dataset.hybrid_search("  ").all
      expect(got).to have_same_ids_as(geralt, ciri)
      got = model.dataset.hybrid_search(" * ").all
      expect(got).to have_same_ids_as(geralt, ciri)
    end

    it "uses OR for the keyword search (instead of 'AND')" do
      m1 = model.create(name: "Tim 1")
      m2 = model.create(name: "Tim 2")
      m3 = model.create(name: "Barry")
      model.hybrid_search_reindex_all

      got = model.dataset.hybrid_search("Tim and here is a bunch of extra text").all
      expect(got).to have_same_ids_as(m2, m1)

      got = model.dataset.hybrid_search("Barry Tim").all
      expect(got).to have_same_ids_as(m1, m2, m3)
    end

    it "can be paginated" do
      models = Array.new(5) { |i| model.create(name: "Tim", created_at: i.days.ago) }
      model.hybrid_search_reindex_all

      q = "testers named Tim, ordered by their created_at field"
      # We cannot rely on the ordering here, unfortunately. So just capture the rows and use their order.
      rows = model.dataset.hybrid_search(q).all
      expect(rows).to have_same_ids_as(models)

      page = model.dataset.hybrid_search(q).limit(2, 0).all
      expect(page).to have_same_ids_as(rows[0], rows[1]).ordered

      page = model.dataset.hybrid_search(q).limit(2, 2).all
      expect(page).to have_same_ids_as(rows[2], rows[3]).ordered

      page = model.dataset.hybrid_search(q).limit(2, 4).all
      expect(page).to have_same_ids_as(rows[4]).ordered
    end
  end

  describe "indexing" do
    before(:each) do
      SequelHybridSearch.indexing_mode = :sync
    end

    it "happens after create" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      expect(geralt.refresh).to have_attributes(search_embedding: have_length(384))
    end

    it "happens after update" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      geralt.this.update(search_embedding: nil)
      expect(geralt.refresh.values[:search_embedding]).to be_nil
      geralt.update(name: "Ciri")
      expect(geralt.refresh).to have_attributes(search_embedding: have_length(384))
    end

    it "noops if the text did not change" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      geralt.this.update(search_embedding: nil)
      expect(geralt.refresh.values[:search_embedding]).to be_nil
      geralt.update(unrelated: "Ciri")
      expect(geralt.refresh.values[:search_embedding]).to be_nil
    end

    it "sets the search content to just values after a colon, and exclues symbol-only lines" do
      geralt = model.create(name: "Geralt")
      expect(geralt.refresh).to have_attributes(search_content: match(/\Asvs tester\n\d+\nGeralt\Z/))
      geralt.update(desc: "of Rivia")
      expect(geralt.refresh).to have_attributes(search_content: match(/\Asvs tester\n\d+\nGeralt\nof Rivia\Z/))
      geralt.update(desc: "[]")
      expect(geralt.refresh).to have_attributes(search_content: match(/\Asvs tester\n\d+\nGeralt\Z/))
      geralt.update(desc: "😀")
      expect(geralt.refresh).to have_attributes(search_content: match(/\Asvs tester\n\d+\nGeralt\n😀\Z/))
    end

    it "can load and overwrite a legacy hash" do
      geralt = model.create(name: "Geralt")
      geralt.this.update(search_hash: "abc-xyz")
      expect(geralt.refresh).to have_attributes(search_hash: "abc-xyz")
      geralt.update(name: "Ciri")
      expect(geralt.refresh).to have_attributes(search_hash: match(/^v2\.[a-f0-9]{32}\.\d{16}$/))
    end

    it "noops if the current search has was generated after the current time" do
      # Here is the race conditions:
      #
      # T0: Model is created
      # T1: Process X updates the model (State 1) and triggers a reindex in Thread A
      # T2: Thread A loads the model (State 1)
      # T3: Process Y updates the model (State 2) and triggers a reindex in Thread B
      # T4: Thread B loads the model (State 2)
      # T5: Thread B reindexes and saves the embeddings (from State 2)
      # T6: Thread A reindexes and saves the embeddings (from State 1)
      #
      # Because for all means and purposes, indexing always happens in a new thread that pulls from the database,
      # we know that when indexing starts, the data we're using is fresh.
      # We need to make sure that when we commit the data, we are not overwriting a thread that loaded data
      # later than we did.
      #
      # This is a challenge to test; using threads and mocking is almost impossible after a half-day of attempts.
      # Instead, we can:
      # 1- create the model
      # 2- open a new connection and a transaction and ask for the current time; this locks in 'now'.
      # 3- update the model in the main thread, in a new transaction, which has a newer 'now'
      # 4- update the model in the old transaction, which should now be stale.

      main_geralt = model.create(name: "Geralt")
      now_captured_event = Concurrent::Event.new
      main_updated_event = Concurrent::Event.new

      t = Thread.new do
        g = model.with_pk!(main_geralt.id)
        model.db.transaction do
          model.db << "SELECT now()"
          now_captured_event.set
          main_updated_event.wait
          g.update(name: "Geralt2")
        end
      end

      now_captured_event.wait
      main_geralt.update(name: "Geralt1")
      main_updated_event.set
      t.join
      expect(main_geralt.refresh).to have_attributes(search_content: match(/Geralt1/))
    end

    it "retries a certain number of times before erroring" do
      expect(Kernel).to receive(:sleep).with(4)
      expect(Kernel).to receive(:sleep).with(8)
      expect(SequelHybridSearch.embedding_generator).to receive(:get_embedding).and_raise(RuntimeError)
      expect(SequelHybridSearch.embedding_generator).to receive(:get_embedding).and_raise(RuntimeError)
      expect(SequelHybridSearch.embedding_generator).to receive(:get_embedding).and_call_original
      geralt = model.create(name: "Geralt")
      expect(geralt.refresh).to have_attributes(search_content: match(/Geralt$/))
    end

    it "can exhaust retries" do
      expect(Kernel).to receive(:sleep).with(4)
      expect(Kernel).to receive(:sleep).with(8)
      expect(Kernel).to receive(:sleep).with(16)
      expect(Kernel).to receive(:sleep).with(32)
      e = RuntimeError.new("hi")
      expect(SequelHybridSearch.embedding_generator).to receive(:get_embedding).and_raise(e).exactly(5).times
      expect { model.create(name: "Geralt") }.to raise_error(e)
    end

    it "runs after the current transaction has committed when using :async mode" do
      SequelHybridSearch.indexing_mode = :async
      o = model.create(name: "Geralt")
      o.define_singleton_method(:around_save) do |&b|
        b.call
        # We want to test that reindexing happens AFTER this block returns (transaction commits).
        # We cannot use events to test this, since once the fix is in place, the reindexing thread
        # won't run until this block return. So we cannot wait here for indexing to finish,
        # since it won't even have started.
        # Instead, we can do a short sleep, which without the after_commit hook almost always makes this test fail,
        # and is still safe to use once after_commit is in place.
        sleep(0.05)
      end
      o.update(name: "Geralt1")
      SequelHybridSearch.threadpool.shutdown
      SequelHybridSearch.threadpool.wait_for_termination
      expect(o.refresh).to have_attributes(search_content: match(/Geralt1/))
    end
  end

  def getvector
    return @db[:svs_tester].order(:id).select(:search_embedding).all.map { |row| row[:search_embedding] }.first
  end

  describe "mode" do
    it "does not index when :off" do
      SequelHybridSearch.indexing_mode = :off
      model.create(name: "ciri")
      expect(getvector).to be_nil
    end

    it "indexes when :sync" do
      SequelHybridSearch.indexing_mode = :sync
      model.create(name: "ciri")
      expect(getvector).to be_present
    end

    it "indexes in a pool when :async" do
      SequelHybridSearch.indexing_mode = :async
      model.create(name: "ciri")
      sleep 1
      SequelHybridSearch.threadpool.shutdown
      SequelHybridSearch.threadpool.wait_for_termination
      expect(getvector).to be_present
    end
  end

  describe "reindexing" do
    it "can reindex all subclasses" do
      SequelHybridSearch.indexing_mode = :sync
      m1 = Class.new(Sequel::Model(:svs_tester)) do
        plugin :hybrid_search
        def hybrid_search_text = "hello"
      end
      m1.dataset = @db[:svs_tester]
      m2 = Class.new(Sequel::Model(:svs_tester)) do
        plugin :hybrid_search
        def hybrid_search_text = "hello"
      end
      m2.dataset = @db[:svs_tester]
      m1.create(name: "x")
      m2.create(name: "y")
      expect(@db[:svs_tester].where(search_embedding: nil).all).to be_empty
      @db[:svs_tester].update(search_embedding: nil, search_hash: nil)
      expect(@db[:svs_tester].where(search_embedding: nil).all).to have_length(2)
      SequelHybridSearch.reindex_all
      expect(@db[:svs_tester].where(search_embedding: nil).all).to be_empty
    end
  end

  describe "subprocess embeddings generator" do
    it "restarts the embedding generator process on broken pipe" do
      gen = SequelHybridSearch::SubprocSentenceTransformerGenerator.instance
      gen.get_embedding("abc")
      Process.kill("TERM", gen.process.fetch(:pid))
      expect { gen.get_embedding("abc") }.to_not raise_error
    end

    it "does not block on stderr filling up" do
      gen = SequelHybridSearch::SubprocSentenceTransformerGenerator.instance
      Array.new(1000) do |i|
        gen.get_embedding(i.to_s)
      end
    end
  end

  describe "api embeddings generator" do
    before(:all) do
      @apikey = "rubytest"
      chdir = Dir.pwd + "/aiapi"
      _, stderr, status = Open3.capture3("pip", "install", "-r", "requirements.txt", chdir:)
      raise "Pip install failed with #{status.exitstatus}: #{stderr}" unless status.success?
      _, _, _, @status = Open3.popen3(
        {"API_KEY" => @apikey},
        "python", "-m", "gunicorn", "--bind", "0.0.0.0:22009", "server:app",
        chdir:,
      )
      sleep(2)
    end

    after(:all) do
      Process.kill("TERM", @status.pid) if @status
    end

    before(:each) do
      WebMock.allow_net_connect!
    end

    it "calls the service" do
      gen = SequelHybridSearch::ApiEmbeddingGenerator.new("http://localhost:22009", api_key: @apikey)
      got = gen.get_embedding("hello")
      expect(got).to have_length(be > 4)
    end

    it "errors for an invalid api key" do
      gen = SequelHybridSearch::ApiEmbeddingGenerator.new("http://localhost:22009", api_key: "badkey")
      expect do
        gen.get_embedding("hello")
      end.to raise_error(/Invalid Api-Key header/)
    end
  end

  describe "patches" do
    it "fixes pgvector decode on a nil emebedding" do
      m = model.create(search_embedding: nil)
      expect(m).to have_attributes(search_embedding: nil)
      expect(m.refresh).to have_attributes(search_embedding: nil)

      m.update(search_embedding: [1] * 384)
      expect(m).to have_attributes(search_embedding: [1] * 384)
      expect(m.refresh).to have_attributes(search_embedding: [1] * 384)
    end
  end
end
