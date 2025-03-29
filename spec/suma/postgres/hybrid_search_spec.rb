# frozen_string_literal: true

RSpec.describe Suma::Postgres::HybridSearch do
  describe "configuration" do
    before(:each) do
      described_class.reset_configuration
    end
    after(:each) do
      described_class.reset_configuration
    end

    it "sets the embedding generator to nil if not configured" do
      SequelHybridSearch.embedding_generator = 5
      described_class.embedding_generator = nil
      described_class.run_after_configured_hooks
      expect(SequelHybridSearch.embedding_generator).to be_nil
    end

    it "configures the hybrid search subproc embedding generator" do
      described_class.embedding_generator = "subprocess"
      described_class.run_after_configured_hooks
      expect(SequelHybridSearch.embedding_generator).to be_a(
        SequelHybridSearch::SubprocSentenceTransformerGenerator,
      )
    end

    it "configures the hybrid search aiapi embedding generator" do
      described_class.embedding_generator = "api"
      described_class.aiapi_host = "http://a.b"
      described_class.aiapi_key = "apikey"
      described_class.run_after_configured_hooks
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
end
