# frozen_string_literal: true

require "open3"

class SequelHybridSearchable::ApiEmbeddingGenerator < SequelHybridSearchable::EmbeddingGenerator
  include Appydays::Loggable

  DEFAULT_MODEL = "all-MiniLM-L6-v2"

  attr_reader :model_name

  # Create a new instance.
  # @param model_name [String] Default to +DEFAULT_MODEL+.
  def initialize(host, model_name=nil)
    super()
    @host = host
    @model_name = model_name || DEFAULT_MODEL
  end

  def get_embedding(text)
    self.logger.debug("encoding_model_embedding", text:)
    url = URI(@host + "/embedding")
    body = JSON.generate({text:, model_name: @model_name})
    resp = Net::HTTP.post(url, body, {"Content-Type" => "application/json"})
    raise "request failed: #{resp.code} #{resp.body}" unless resp.code == "200"
    rbody = JSON.parse(resp.body)
    embedding = rbody.fetch("embedding")
    self.logger.debug("encoded_model_embedding", text:, vector_size: embedding.size)
    return embedding
  end
end
