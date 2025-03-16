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
      column :embeddings, Sequel.lit("vector(384)")
      text :embeddings_hash
    end
    SequelVectorSearchable::Indexing.mode = :off
  end

  after(:all) do
    @db.disconnect
    SequelVectorSearchable::Indexing.mode = :off
  end

  before(:each) do
    @db[:svs_tester].truncate
  end

  let(:model) do
    m = Class.new(Sequel::Model(:svs_tester)) do
      plugin :vector_searchable
      many_to_one :parent, class: self
      def vector_search_text
        return <<~TEXT
          This is a test model. it may have a parent which is also a test model. It has the following fields:
          id: #{self.id}
          name: #{self.name}
          description: #{self.desc}
          parent id: #{self.parent_id}"
        TEXT
      end
    end
    m.dataset = @db[:svs_tester]
    m
  end

  describe "configuration" do
    it "errors for an invalid index mode" do
      expect do
        SequelVectorSearchable::Indexing.mode = :x
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
      o = m.new
      expect { o.vector_search_text }.to raise_error(NotImplementedError)
    end

    it "errors if setup is called from the non-main thread" do
      t = Thread.new do
        Thread.current.report_on_exception = false
        Thread.current.abort_on_exception = true
        SequelVectorSearchable::Embeddings.setup
      end
      expect { t.join }.to raise_error(/must be called on the main thread/)
    end
  end

  it "indexes after save and can search" do
    geralt = model.create(name: "Geralt", desc: "Rivia")
    ciri = model.create(name: "Rivia", desc: "Ciri")
    model.vector_search_reindex_all

    # expect(model.dataset.vector_search("test models with the name field 'geralt'").all).to have_same_ids_as(geralt)
    # expect(model.dataset.vector_search("with the name or description 'rivia'").all).to have_same_ids_as(geralt, ciri)
    # ciri.update(name: "Ciri")
    # model.vector_search_remodel(ciri.pk)
    # expect(model.dataset.vector_search("with the name or description 'rivia'").all).to have_same_ids_as(geralt)
  end

  describe "indexing" do
    before(:each) do
      SequelVectorSearchable::Indexing.mode = :sync
    end

    it "happens after create" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      expect(model.dataset.vector_search("geralt").all).to have_same_ids_as(geralt)
    end

    it "happens after update" do
      geralt = model.create(name: "Geralt", desc: "Rivia")
      expect(geralt).to receive(:vector_search_reindex).and_call_original
      geralt.update(name: "Ciri")
      expect(model.dataset.vector_search("ciri").all).to have_same_ids_as(geralt)
    end
  end

  def getvector
    return @db[:svs_tester].order(:id).select(:embeddings).all.map { |row| row[:embeddings] }.first
  end

  describe "mode" do
    it "does not index when :off" do
      SequelVectorSearchable::Indexing.mode = :off
      model.create(name: "ciri")
      expect(getvector).to be_nil
    end

    it "indexes when :sync" do
      SequelVectorSearchable::Indexing.mode = :sync
      model.create(name: "ciri")
      expect(getvector).to be_present
    end

    it "indexes in a pool when :async" do
      SequelVectorSearchable::Indexing.mode = :async
      model.create(name: "ciri")
      sleep 1
      SequelVectorSearchable::Indexing.threadpool.shutdown
      SequelVectorSearchable::Indexing.threadpool.wait_for_termination
      expect(getvector).to be_present
    end
  end

  describe "reindexing" do
    it "can reindex all subclasses" do
      SequelVectorSearchable::Indexing.mode = :sync
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
      expect(@db[:svs_tester].where(embeddings: nil).all).to be_empty
      @db[:svs_tester].update(embeddings: nil)
      expect(@db[:svs_tester].where(embeddings: nil).all).to have_length(2)
      SequelVectorSearchable::Indexing.reindex_all
      expect(@db[:svs_tester].where(embeddings: nil).all).to be_empty
    end
  end
end
