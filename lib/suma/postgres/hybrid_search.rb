# frozen_string_literal: true

module Suma::Postgres::HybridSearch
  include Appydays::Configurable

  configurable(:hybrid_search) do
    # When changing this:
    # - All vectors should be regenerated, using Suma::Async::HybridSearchReindex
    # - The model must use the same vector size (like vector(384)).
    #   If the vector size is changing, database migrations must be done.
    setting :model, "all-MiniLM-L12-v2"

    # Valid values are:
    # - subprocess
    # - api
    setting :embedding_generator, nil

    setting :aiapi_host, nil
    setting :aiapi_key, "fake-key"

    after_configured do
      if self.embedding_generator == "subprocess"
        require "sequel/sequel_hybrid_search/subproc_sentence_transformer_generator"
        SequelHybridSearch.embedding_generator = SequelHybridSearch::SubprocSentenceTransformerGenerator.new(
          self.model,
        )
      elsif self.embedding_generator == "api"
        require "sequel/sequel_hybrid_search/api_embedding_generator"
        require "suma/http"
        raise "Must set SUMA_DB_HYBRID_SEARCH_AIAPI_HOST" if self.aiapi_host.blank?
        SequelHybridSearch.embedding_generator = SequelHybridSearch::ApiEmbeddingGenerator.new(
          self.aiapi_host,
          api_key: self.aiapi_key,
          user_agent: Suma::Http.user_agent,
          model_name: self.model,
        )
      else
        require "sequel/sequel_hybrid_search"
        SequelHybridSearch.embedding_generator = nil
      end
    end
  end

  def hybrid_search_text
    lines = [
      "I am a #{self.class.name.gsub('::', ' ')}.",
    ]
    if (fields = self.hybrid_search_fields).present?
      lines << "I have the following fields:"
      fields.unshift(:created_at) if !fields.include?(self.class.primary_key) && self.respond_to?(:created_at)
      fields.unshift(self.class.primary_key) unless fields.include?(self.class.primary_key)
      fields.each do |field|
        if field.is_a?(Symbol)
          k = field.to_s.humanize
          v = self.send(field)
        else
          k, v = field
        end
        v = v.utc.strftime("%A, %B %-d, %Y, %k:%M:%S GMT") if v.respond_to?(:strftime)
        v = v.format if v.is_a?(Money)
        v = v.name if v.respond_to?(:name)
        v = v.en if v.is_a?(Suma::TranslatedText)
        lines << "#{k}: #{v}"
      end
    end
    if (facts = self.hybrid_search_facts).present?
      lines << "The following facts are known about me:"
      lines.concat(facts)
    end
    return lines.select(&:present?).join("\n")
  end

  def hybrid_search_fields = []
  def hybrid_search_facts = []
end
