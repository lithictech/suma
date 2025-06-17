# frozen_string_literal: true

# For Server Sent Events, we use a simple auth.
# We expose an 'SSE token' through certain endpoints a user must be authed to access.
# The token is just an encrypted JSON document which contains how long the token is valid for;
# if the token is valid, then SSE can be used.
# In the future we could use a JWT, add scopes, etc.
#
# The TTL is short because once the event session is established, it stays open.
module Suma::SSE::Auth
  HEADER = "Suma-Events-Token"
  TTL = 5.minutes

  class << self
    def cipher = OpenSSL::Cipher.new("aes-256-cbc")
    def key = @key ||= cipher.random_key
    def iv = @iv ||= cipher.random_iv

    def generate_token
      c = self.cipher
      c.encrypt
      c.key = self.key
      c.iv = self.iv

      payload = {exp: (Time.now + TTL).to_i}
      plain = payload.to_json
      encrypted = c.update(plain) + c.final
      b64 = Base64.urlsafe_encode64(encrypted)
      encoded = URI.encode_uri_component(b64)
      return encoded
    end

    def validate_token(encoded_token)
      d = self.cipher
      d.decrypt
      d.key = self.key
      d.iv = self.iv
      b64 = URI.decode_uri_component(encoded_token)
      encrypted = Base64.urlsafe_decode64(b64)
      plain = d.update(encrypted) + d.final
      payload = JSON.parse(plain)
      ttl = Time.now + TTL
      return payload["exp"] < ttl.to_i
    end
  end
end
