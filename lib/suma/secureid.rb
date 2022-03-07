# frozen_string_literal: true

require "suma"

module Suma::Secureid
  ID_BYTES = 16
  SHORT_ID_BYTES = 4

  def self.new_token
    return self.rand_enc(ID_BYTES)
  end

  def self.new_short_token
    return self.rand_enc(SHORT_ID_BYTES)
  end

  def self.new_opaque_id(prefix)
    b36 = self.rand_enc(ID_BYTES)
    return "#{prefix}_#{b36}"
  end

  def self.rand_enc(blen)
    b = SecureRandom.bytes(blen)
    return Digest.hexencode(b).to_i(16).to_s(36)
  end
end
