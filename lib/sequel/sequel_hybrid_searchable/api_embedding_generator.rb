# frozen_string_literal: true

require "open3"
require "sequel/sequel_hybrid_searchable"

class SequelHybridSearchable::ApiEmbeddingGenerator < SequelHybridSearchable::EmbeddingGenerator
  include Appydays::Loggable

  DEFAULT_MODEL = "all-MiniLM-L12-v2"

  attr_reader :model_name, :host, :api_key

  # Create a new instance.
  # @param model_name [String] Default to +DEFAULT_MODEL+.
  def initialize(host, api_key:, model_name: nil)
    super()
    @host = host
    @api_key = api_key
    @model_name = model_name || DEFAULT_MODEL
  end

  def get_embedding(text)
    self.logger.debug("encoding_model_embedding", text:)
    url = URI(@host + "/embedding")
    body = JSON.generate({text:, model_name: @model_name})
    headers = {
      "Content-Type" => "application/json",
      "Api-Key" => @api_key,
    }
    resp = Net::HTTP.post(url, body, headers)
    raise "request failed: #{resp.code} #{resp.body}" unless resp.code == "200"
    rbody = JSON.parse(resp.body)
    embedding = rbody.fetch("embedding")
    self.logger.debug("encoded_model_embedding", text:, vector_size: embedding.size)
    return embedding
  end
end
