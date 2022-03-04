# frozen_string_literal: true

require "faker"

require "suma"
require "suma/fixtures"
require "suma/customer"

module Suma::Fixtures::Sessions
  extend Suma::Fixtures

  fixtured_class Suma::Customer::Session

  base :session do
    self.peer_ip ||= Faker::Internet.ip_v4_address
    self.user_agent ||= Faker::Internet.user_agent
  end

  before_saving do |instance|
    instance.customer ||= Suma::Fixtures.customer.create
    instance
  end

  decorator :android_webview do
    self.user_agent = "Mozilla/5.0 (Linux; Android 5.1.1; Nexus 5 Build/LMY48B; wv) AppleWebKit/537.36 "\
                      "(KHTML, like Gecko) Version/4.0 Chrome/43.0.2357.65 Mobile Safari/537.36"
  end

  decorator :ios_webview do
    self.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 8_4 like Mac OS X) "\
                      "AppleWebKit/600.1.4 (KHTML, like Gecko) Mobile/12H141"
  end

  decorator :android_app do
    self.user_agent = "com.mysuma.suma / 1.0.4-android OS/Android-11 BuildTime/1613071039431 Device/Pixel 2"
  end

  decorator :ios_app do
    self.user_agent = "com.mysuma.suma / 2.20.40-ios OS/iOS-13.5 BuildTime/1613071039431 Device/iPhone"
  end

  decorator :android_default do
    self.user_agent = "okhttp/3.12.1"
  end

  decorator :ios_default do
    self.user_agent = "MySuma/1.0.3 CFNetwork/1128.0.1 Darwin/19.6.0"
  end
end
