# frozen_string_literal: true

require "sequel"
require "sequel/sequel_hybrid_searchable"

RSpec.describe "sequel-hybrid-searchable" do
  before(:all) do
    dburl = ENV.fetch("DATABASE_URL", nil)
    @db = Sequel.connect(dburl)
    @db.drop_table?(:svs_tester)
    @db.create_table(:svs_tester) do
      primary_key :id
      text :name
      text :desc
      integer :parent_id
      text :unrelated
      text :search_content
      column :search_embedding, Sequel.lit("vector(384)")
      text :search_hash
      column :search_tsv,
             "tsvector",
             generated_always_as: Sequel.function(:to_tsvector, "english", Sequel[:search_content])
    end
    SequelHybridSearchable.indexing_mode = :off
    @searchable = SequelHybridSearchable.searchable_models.dup
  end

  after(:all) do
    @db.disconnect
    SequelHybridSearchable.indexing_mode = :off
  end

  before(:each) do
    @db[:svs_tester].truncate
    SequelHybridSearchable.searchable_models.clear
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
          parent name: #{self.parent&.name}"
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
               hash_column: :hcol,
               tsvector_column: :tcol
      end
      expect(m.hybrid_search_content_column).to eq(:ccol)
      expect(m.hybrid_search_vector_column).to eq(:vcol)
      expect(m.hybrid_search_hash_column).to eq(:hcol)
      expect(m.hybrid_search_tsvector_column).to eq(:tcol)
    end

    it "errors if hybrid_search_text is not defined" do
      m = Class.new(Sequel::Model(:svs_tester)) do
        plugin :hybrid_searchable
      end
      SequelHybridSearchable.searchable_models.delete(m) # Don't leave this sitting around
      o = m.new
      expect { o.hybrid_search_text }.to raise_error(NotImplementedError)
    end
  end

  it "indexes after save and can search" do
    geralt = model.create(name: "Geralt", desc: "Rivia")
    ciri = model.create(name: "Rivia", desc: "Ciri")
    model.hybrid_search_reindex_all

    expect(model.dataset.hybrid_search("test models named 'geralt'").all).to have_same_ids_as(geralt, ciri).ordered
    expect(model.dataset.hybrid_search("test models named 'ciri'").all).to have_same_ids_as(ciri, geralt).ordered
  end

  it "restarts the embedding generator process on broken pipe" do
    SequelHybridSearchable.embedding_generator.get_embedding("abc")
    Process.kill("TERM", SequelHybridSearchable.embedding_generator.process.fetch(:pid))
    expect { SequelHybridSearchable.embedding_generator.get_embedding("abc") }.to_not raise_error
  end

  describe "search" do
    it "performs a hybrid semantic and keyword search" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      ciri = model.create(name: "Rivia", desc: "Ciri")
      model.hybrid_search_reindex_all

      expect(model.dataset.hybrid_search("test models named 'geralt'").all).to have_same_ids_as(geralt, ciri).ordered
      expect(model.dataset.hybrid_search("test models named 'ciri'").all).to have_same_ids_as(ciri, geralt).ordered
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
end
