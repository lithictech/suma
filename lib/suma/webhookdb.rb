# frozen_string_literal: true

require "appydays/configurable"

module Suma::Webhookdb
  include Appydays::Configurable

  class << self
    attr_accessor :connection

    def plivo_messages_dataset
      return self.connection[Sequel[self.schema][self.plivo_messages_table]]
    end

    def postmark_inbound_messages_dataset
      return self.connection[Sequel[self.schema][self.postmark_inbound_messages_table]]
    end
  end

  configurable(:webhookdb) do
    setting :database_url, ENV.fetch("DATABASE_URL", nil)
    setting :schema, :public
    setting :plivo_messages_table, :webhookdb_plivo_messages_fixture
    setting :postmark_inbound_messages_table, :webhookdb_postmark_inbound_messages_fixture

    after_configured do
      self.connection = Sequel.connect(self.database_url, extensions: [:pg_json])
    end
  end
end
