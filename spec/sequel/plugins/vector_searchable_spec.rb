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
    SequelVectorSearchable.index_mode = :off
  end

  after(:all) do
    @db.disconnect
    SequelVectorSearchable.index_mode = :off
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
          this is a test model. it may have a parent which is also a test model
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
        SequelVectorSearchable.index_mode = :x
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
  end

  it "indexes after save and can search" do
    geralt = model.create(name: "Geralt", desc: "Rivia")
    ciri = model.create(name: "Rivia", desc: "Ciri")
    model.vector_search_reindex_all

    expect(model.dataset.vector_search("geralt").all).to have_same_ids_as(geralt)
    expect(model.dataset.vector_search("rivia").all).to have_same_ids_as(geralt, ciri)
    ciri.update(name: "Ciri")
    model.vector_search_reindex_model(ciri.pk)
    expect(model.dataset.vector_search("rivia").all).to have_same_ids_as(geralt)
  end

  describe "indexing" do
    before(:each) do
      SequelVectorSearchable.index_mode = :sync
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
  #
  # def getvector
  #   return @db[:svs_tester].order(:id).select(:text_search).all.map { |row| row[:text_search] }.first
  # end
  #
  # describe "index_mode" do
  #   it "does not index when :off" do
  #     SequelVectorSearchable.index_mode = :off
  #     model.create(name: "ciri")
  #     expect(getvector).to be_nil
  #   end
  #
  #   it "indexes when :sync" do
  #     SequelVectorSearchable.index_mode = :sync
  #     model.create(name: "ciri")
  #     expect(getvector).to eq("'ciri':1A")
  #   end
  #
  #   it "indexes in a pool when :async" do
  #     SequelVectorSearchable.index_mode = :async
  #     model.create(name: "ciri")
  #     SequelVectorSearchable.threadpool.shutdown
  #     SequelVectorSearchable.threadpool.wait_for_termination
  #     expect(getvector).to eq("'ciri':1A")
  #   end
  # end
  #
  # describe "text_search_terms" do
  #   it "calculates the tsvector properly based on all terms" do
  #     c1 = model.create(name: "Ciri")
  #     c1.text_search_reindex
  #     expect(getvector).to eq("'ciri':1A")
  #
  #     c1.update(desc: "'witcher")
  #     c1.text_search_reindex
  #     expect(getvector).to eq("'ciri':1A 'witcher':2")
  #
  #     c1.update(parent: model.create(desc: "geralt"))
  #     c1.text_search_reindex
  #     expect(getvector).to eq("'ciri':1A 'geralt':3 'witcher':2")
  #
  #     c1.parent.define_singleton_method(:text_search_terms_for_related) { ["princess"] }
  #     c1.text_search_reindex
  #     expect(getvector).to eq("'ciri':1A 'princess':3 'witcher':2")
  #   end
  #
  #   it "flattens deeply nested terms, removing parent ranks" do
  #     gp = model.create(name: "grandparent")
  #     p = model.create(name: "parent", parent: gp)
  #     c = model.create(name: "child", parent: p)
  #     gc = model.create(name: "grandchild", parent: c)
  #     model.text_search_reindex_all
  #     expect(gp.refresh).to have_attributes(text_search: "'grandpar':1A")
  #     expect(p.refresh).to have_attributes(text_search: "'grandpar':2 'parent':1A")
  #     expect(c.refresh).to have_attributes(text_search: "'child':1A 'grandpar':3 'parent':2")
  #     expect(gc.refresh).to have_attributes(text_search: "'child':2 'grandchild':1A 'grandpar':4 'parent':3")
  #   end
  #
  #   it "handles hashes instead of strings and tuples" do
  #     c1 = model.create(name: "Ciri")
  #     c1.define_singleton_method(:text_search_terms) { [{"ciri" => "B"}, {"geralt" => "C"}] }
  #     c1.text_search_reindex
  #     expect(getvector).to eq("'ciri':1B 'geralt':2C")
  #
  #     c1.define_singleton_method(:text_search_terms) { {"ciri" => "A", "geralt" => "C"} }
  #     c1.text_search_reindex
  #     expect(getvector).to eq("'ciri':1A 'geralt':2C")
  #   end
  # end
  #
  # describe "reindexing" do
  #   it "can reindex all subclasses" do
  #     SequelVectorSearchable.index_mode = :sync
  #     m1 = Class.new(Sequel::Model(:svs_tester)) do
  #       plugin :dirty
  #       plugin :text_searchable, terms: [:name]
  #     end
  #     m1.dataset = @db[:svs_tester]
  #     m2 = Class.new(Sequel::Model(:svs_tester)) do
  #       plugin :dirty
  #       plugin :text_searchable, terms: [:name]
  #     end
  #     m2.dataset = @db[:svs_tester]
  #     m1.create(name: "x")
  #     m2.create(name: "y")
  #     expect(@db[:svs_tester].where(text_search: nil).all).to be_empty
  #     @db[:svs_tester].update(text_search: nil)
  #     expect(@db[:svs_tester].where(text_search: nil).all).to have_length(2)
  #     SequelVectorSearchable.reindex_all
  #     expect(@db[:svs_tester].where(text_search: nil).all).to be_empty
  #   end
  # end
end
