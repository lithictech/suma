# frozen_string_literal: true

require "sequel"
require "sequel/sequel_hybrid_searchable"
require "sequel/sequel_hybrid_searchable/subproc_sentence_transformer_generator"
require "sequel/sequel_hybrid_searchable/api_embedding_generator"

RSpec.describe "sequel-hybrid-searchable" do
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
    SequelHybridSearchable.indexing_mode = :off
    @searchable = SequelHybridSearchable.searchable_models.dup
  end

  after(:all) do
    @db.disconnect
    SequelHybridSearchable.indexing_mode = :off
    SequelHybridSearchable.embedding_generator = nil
  end

  before(:each) do
    @db[:svs_tester].truncate
    SequelHybridSearchable.searchable_models.clear
    SequelHybridSearchable.indexing_mode = :off
    SequelHybridSearchable.embedding_generator = SequelHybridSearchable::SubprocSentenceTransformerGenerator
  end

  after(:each) do
    SequelHybridSearchable.searchable_models.replace(@searchable)
  end

  let(:model) do
    m = Class.new(Sequel::Model(:svs_tester)) do
      plugin :hybrid_searchable
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
        SequelHybridSearchable.indexing_mode = :x
      end.to raise_error(/must be one of/)
    end

    it "can define custom options" do
      m = Class.new(Sequel::Model(:svs_tester)) do
        plugin :hybrid_searchable,
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
        plugin :hybrid_searchable
      end
      SequelHybridSearchable.searchable_models.delete(m) # Don't leave this sitting around
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
    it "performs a hybrid semantic and keyword search" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      ciri = model.create(name: "Rivia", desc: "Ciri")
      model.hybrid_search_reindex_all

      got = model.dataset.hybrid_search("test models named 'geralt'").first
      expect(got).to be_a(model)
      expect(got).to have_attributes(id: geralt.id, name: "Geralt")
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
      SequelHybridSearchable.indexing_mode = :sync
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

    it "sets the search content to just values after a colon" do
      geralt = model.create(name: "Geralt")
      expect(geralt.refresh).to have_attributes(search_content: match(/svs tester\n\d+\nGeralt/))
      geralt.update(desc: "of Rivia")
      expect(geralt.refresh).to have_attributes(search_content: match(/svs tester\n\d+\nGeralt\nof Rivia/))
    end
  end

  def getvector
    return @db[:svs_tester].order(:id).select(:search_embedding).all.map { |row| row[:search_embedding] }.first
  end

  describe "mode" do
    it "does not index when :off" do
      SequelHybridSearchable.indexing_mode = :off
      model.create(name: "ciri")
      expect(getvector).to be_nil
    end

    it "indexes when :sync" do
      SequelHybridSearchable.indexing_mode = :sync
      model.create(name: "ciri")
      expect(getvector).to be_present
    end

    it "indexes in a pool when :async" do
      SequelHybridSearchable.indexing_mode = :async
      model.create(name: "ciri")
      sleep 1
      SequelHybridSearchable.threadpool.shutdown
      SequelHybridSearchable.threadpool.wait_for_termination
      expect(getvector).to be_present
    end
  end

  describe "reindexing" do
    it "can reindex all subclasses" do
      SequelHybridSearchable.indexing_mode = :sync
      m1 = Class.new(Sequel::Model(:svs_tester)) do
        plugin :hybrid_searchable
        def hybrid_search_text = "hello"
      end
      m1.dataset = @db[:svs_tester]
      m2 = Class.new(Sequel::Model(:svs_tester)) do
        plugin :hybrid_searchable
        def hybrid_search_text = "hello"
      end
      m2.dataset = @db[:svs_tester]
      m1.create(name: "x")
      m2.create(name: "y")
      expect(@db[:svs_tester].where(search_embedding: nil).all).to be_empty
      @db[:svs_tester].update(search_embedding: nil, search_hash: nil)
      expect(@db[:svs_tester].where(search_embedding: nil).all).to have_length(2)
      SequelHybridSearchable.reindex_all
      expect(@db[:svs_tester].where(search_embedding: nil).all).to be_empty
    end
  end

  describe "subprocess embeddings generator" do
    it "restarts the embedding generator process on broken pipe" do
      gen = SequelHybridSearchable::SubprocSentenceTransformerGenerator.instance
      gen.get_embedding("abc")
      Process.kill("TERM", gen.process.fetch(:pid))
      expect { gen.get_embedding("abc") }.to_not raise_error
    end

    it "does not block on stderr filling up" do
      Array.new(1000) do |i|
        SequelHybridSearchable.embedding_generator.get_embedding(i.to_s)
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
      gen = SequelHybridSearchable::ApiEmbeddingGenerator.new("http://localhost:22009", api_key: @apikey)
      got = gen.get_embedding("hello")
      expect(got).to have_length(be > 4)
    end

    it "errors for an invalid api key" do
      gen = SequelHybridSearchable::ApiEmbeddingGenerator.new("http://localhost:22009", api_key: "badkey")
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
