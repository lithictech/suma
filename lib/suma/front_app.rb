# frozen_string_literal: true

class Suma::FrontApp
  include Appydays::Configurable

  configurable(:front) do
    setting :user_verification_secret, "", key: "4dbd5443b0c3a6ca9f37458b761ed929"
  end

  def self.user_email_hash(email)
    h = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), self.user_verification_secret, email)
    return h
  end
end
