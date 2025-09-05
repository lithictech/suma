# frozen_string_literal: true

require_relative "../behaviors"

RSpec.describe Suma::Postgres::HybridSearch, :db do
  describe "configuration" do
    before(:each) do
      described_class.reset_configuration
    end
    after(:each) do
      described_class.reset_configuration
    end

    it "sets the embedding generator to nil if not configured" do
      SequelHybridSearch.embedding_generator = 5
      described_class.reset_configuration(embedding_generator: nil)
      expect(SequelHybridSearch.embedding_generator).to be_nil
    end

    it "configures the hybrid search subproc embedding generator" do
      described_class.reset_configuration(embedding_generator: "subprocess")
      expect(SequelHybridSearch.embedding_generator).to be_a(
        SequelHybridSearch::SubprocSentenceTransformerGenerator,
      )
    end

    it "configures the hybrid search aiapi embedding generator" do
      described_class.reset_configuration(
        embedding_generator: "api",
        aiapi_host: "http://a.b",
        aiapi_key: "apikey",
      )
      expect(SequelHybridSearch.embedding_generator).to be_a(
        SequelHybridSearch::ApiEmbeddingGenerator,
      )
      expect(SequelHybridSearch.embedding_generator).to have_attributes(
        host: "http://a.b",
        api_key: "apikey",
      )
    end

    it "errors for a blank api host if configured" do
      described_class.embedding_generator = "api"
      described_class.aiapi_host = nil
      expect do
        described_class.run_after_configured_hooks
      end.to raise_error(/SUMA_DB_HYBRID_SEARCH_AIAPI_HOST/)
    end
  end

  describe "hybrid search text" do
    it "adds standard fields" do
      m = Suma::Fixtures.member.create
      expect(m.hybrid_search_text).to include("Id: #{m.id}")
      expect(m.hybrid_search_text).to include("Created at:")
    end

    it "formats times" do
      m = Suma::Fixtures.member.create
      m.created_at = Time.parse("2023-01-01T12:00:00Z")
      expect(m.hybrid_search_text).to include("Created at: Sunday, January 1, 2023, 12:00:00 GMT")
    end
  end

  describe "all hybrid searchable models" do
    SequelHybridSearch.indexable_models.each do |m|
      describe m.name do
        it_behaves_like "a hybrid searchable object" do
          let(:instance) do
            mod = Suma::Fixtures.fixture_module_for(m)
            fac = mod.ensure_fixturable(mod.base_factory)
            fac.create
          end
        end
      end
    end
  end
end
