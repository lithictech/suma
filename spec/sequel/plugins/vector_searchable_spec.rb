# frozen_string_literal: true

require "sequel"
require "sequel/sequel_vector_searchable"

RSpec.describe "sequel-vector-searchable" do
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
      column :embedding, Sequel.lit("vector(384)")
      text :embedding_hash
    end
    SequelVectorSearchable.indexing_mode = :off
    @searchable = SequelVectorSearchable.searchable_models.dup
  end

  after(:all) do
    @db.disconnect
    SequelVectorSearchable.indexing_mode = :off
  end

  before(:each) do
    @db[:svs_tester].truncate
    SequelVectorSearchable.searchable_models.clear
  end

  after(:each) do
    SequelVectorSearchable.searchable_models.replace(@searchable)
  end

  let(:model) do
    m = Class.new(Sequel::Model(:svs_tester)) do
      plugin :vector_searchable
      many_to_one :parent, class: self
      def vector_search_text
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
        SequelVectorSearchable.indexing_mode = :x
      end.to raise_error(/must be one of/)
    end

    it "can define custom options" do
      m = Class.new(Sequel::Model(:svs_tester)) do
        plugin :vector_searchable, vector_column: :mycol, hash_column: :mycol2
      end
      expect(m.vector_search_vector_column).to eq(:mycol)
      expect(m.vector_search_hash_column).to eq(:mycol2)
    end

    it "errors if vector_search_text is not defined" do
      m = Class.new(Sequel::Model(:svs_tester)) do
        plugin :vector_searchable
      end
      SequelVectorSearchable.searchable_models.delete(m) # Don't leave this sitting around
      o = m.new
      expect { o.vector_search_text }.to raise_error(NotImplementedError)
    end
  end

  it "indexes after save and can search" do
    geralt = model.create(name: "Geralt", desc: "Rivia")
    ciri = model.create(name: "Rivia", desc: "Ciri")
    model.vector_search_reindex_all

    expect(model.dataset.vector_search("test models named 'geralt'").all).to have_same_ids_as(geralt, ciri).ordered
    expect(model.dataset.vector_search("test models named 'ciri'").all).to have_same_ids_as(ciri, geralt).ordered
  end

  it "restarts a process on broken pipe" do
    SequelVectorSearchable.embedding_generator.get_embedding("abc")
    Process.kill("TERM", SequelVectorSearchable.embedding_generator.process.fetch(:pid))
    expect { SequelVectorSearchable.embedding_generator.get_embedding("abc") }.to_not raise_error
  end

  describe "indexing" do
    before(:each) do
      SequelVectorSearchable.indexing_mode = :sync
    end

    it "happens after create" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      expect(geralt.refresh).to have_attributes(embedding: have_length(384))
    end

    it "happens after update" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      geralt.this.update(embedding: nil)
      expect(geralt.refresh.values[:embedding]).to be_nil
      geralt.update(name: "Ciri")
      expect(geralt.refresh).to have_attributes(embedding: have_length(384))
    end

    it "noops if the text did not change" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      geralt.this.update(embedding: nil)
      expect(geralt.refresh.values[:embedding]).to be_nil
      geralt.update(unrelated: "Ciri")
      expect(geralt.refresh.values[:embedding]).to be_nil
    end
  end

  def getvector
    return @db[:svs_tester].order(:id).select(:embedding).all.map { |row| row[:embedding] }.first
  end

  describe "mode" do
    it "does not index when :off" do
      SequelVectorSearchable.indexing_mode = :off
      model.create(name: "ciri")
      expect(getvector).to be_nil
    end

    it "indexes when :sync" do
      SequelVectorSearchable.indexing_mode = :sync
      model.create(name: "ciri")
      expect(getvector).to be_present
    end

    it "indexes in a pool when :async" do
      SequelVectorSearchable.indexing_mode = :async
      model.create(name: "ciri")
      sleep 1
      SequelVectorSearchable.threadpool.shutdown
      SequelVectorSearchable.threadpool.wait_for_termination
      expect(getvector).to be_present
    end
  end

  describe "reindexing" do
    it "can reindex all subclasses" do
      SequelVectorSearchable.indexing_mode = :sync
      m1 = Class.new(Sequel::Model(:svs_tester)) do
        plugin :vector_searchable
        def vector_search_text = "hello"
      end
      m1.dataset = @db[:svs_tester]
      m2 = Class.new(Sequel::Model(:svs_tester)) do
        plugin :vector_searchable
        def vector_search_text = "hello"
      end
      m2.dataset = @db[:svs_tester]
      m1.create(name: "x")
      m2.create(name: "y")
      expect(@db[:svs_tester].where(embedding: nil).all).to be_empty
      @db[:svs_tester].update(embedding: nil, embedding_hash: nil)
      expect(@db[:svs_tester].where(embedding: nil).all).to have_length(2)
      SequelVectorSearchable.reindex_all
      expect(@db[:svs_tester].where(embedding: nil).all).to be_empty
    end
  end
end
