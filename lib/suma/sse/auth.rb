# frozen_string_literal: true

# For Server Sent Events, we use a simple auth.
# We expose an 'SSE token' through certain endpoints a user must be authed to access.
# The token is just an encrypted JSON document which contains how long the token is valid for;
# if the token is valid, then SSE can be used.
# In the future we could use a JWT, add scopes, etc.
#
# The TTL is short because once the event session is established, it stays open.
module Suma::SSE::Auth
  TTL = 5.minutes

  class Error < StandardError; end
  class Malformed < Error; end
  class Missing < Error; end
  class Expired < Error; end

  class << self
    def cipher = OpenSSL::Cipher.new("aes-256-cbc")
    def key = @key ||= cipher.random_key
    def iv = @iv ||= cipher.random_iv

    def generate_token(now: Time.now)
      c = self.cipher
      c.encrypt
      c.key = self.key
      c.iv = self.iv

      payload = {exp: (now + TTL).to_i}
      plain = payload.to_json
      encrypted = c.update(plain) + c.final
      b64 = Base64.urlsafe_encode64(encrypted)
      # Equal sign ends up being encoded, and can cause issues since this token is being passed around
      # in a body, header, and query param. We don't need to include the padding, so remove it.
      b64.gsub!(/=+$/, "")
      encoded = URI.encode_uri_component(b64)
      return encoded
    end

    def validate_token(tok, now: Time.now)
      self.validate_token!(tok, now:)
      return true
    rescue Error
      return false
    end

    def validate_token!(encoded_token, now: Time.now)
      raise Missing if encoded_token.blank?
      d = self.cipher
      d.decrypt
      d.key = self.key
      d.iv = self.iv
      b64 = URI.decode_uri_component(encoded_token)
      encrypted = Base64.urlsafe_decode64(b64)
      plain = d.update(encrypted) + d.final
      payload = JSON.parse(plain)
      now = now.to_i
      exp = payload["exp"]
      raise Expired if now > exp
    rescue OpenSSL::Cipher::CipherError, KeyError
      raise Malformed
    end
  end
end
