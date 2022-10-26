# frozen_string_literal: true

class Suma::Helcim
  include Appydays::Configurable
  include Appydays::Loggable

  class Error < StandardError; end

  configurable(:helcim) do
    setting :account_id, "helcim_sandbox_account_id"
    setting :api_token, "test_helcim_key"
    setting :host, "https://secure.myhelcim.com"
    setting :app_url, "https://dashboard.myhelcim.com"
    setting :testmode, true
  end

  def self.headers
    return {
      "Account-Id" => self.account_id,
      "Api-Token" => self.api_token,
      "Accept" => "application/xml",
      "Content-Type" => "application/x-www-form-urlencoded",
    }
  end

  def self.make_request(path, body, response_key)
    body[:test] = 1 if self.testmode
    response = Suma::Http.post(
      self.host + path,
      body,
      headers: self.headers,
      logger: self.logger,
    )
    rbod = response.parsed_response
    self.strip_whitespace(rbod)
    rmessage = rbod.fetch("message")
    raise Error, rmessage.fetch("responseMessage") if rmessage.fetch("response") != "1"
    return rmessage.fetch(response_key)
  end

  def self.strip_whitespace(h)
    h.transform_values! do |v|
      case v
        when String
          v.strip
        when Hash
          self.strip_whitespace(v)
      else
          v
      end
    end
    return h
  end

  # https://devdocs.helcim.com/reference/card-pre-authorization
  def self.preauthorize(amount:, token:, ip:, ecommerce: false)
    return self.make_request(
      "/api/card/pre-authorization",
      {
        amount: amount.to_f.to_s,
        cardToken: token,
        cardF4L4Skip: 1,
        ecommerce: ecommerce ? 1 : 0,
        ipAddress: ip,
      },
      "transaction",
    )
  end

  # https://devdocs.helcim.com/reference/card-capture
  def self.capture(transaction_id:, amount: nil)
    body = {
      transactionId: transaction_id,
      amount: amount ? amount.to_f.to_s : "",
    }
    return self.make_request("/api/card/capture", body, "transaction")
  end
end
