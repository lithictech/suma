# frozen_string_literal: true

require "appydays/configurable"

module Suma::Webhookdb
  include Appydays::Configurable

  class << self
    attr_accessor :connection

    def dataset_for_table(table)
      return self.connection[Sequel[self.schema][table]]
    end

    def postmark_inbound_messages_dataset
      return self.dataset_for_table(self.postmark_inbound_messages_table)
    end

    def stripe_refunds_dataset
      return self.dataset_for_table(self.stripe_refunds_table)
    end

    def stripe_charges_dataset
      return self.dataset_for_table(self.stripe_charges_table)
    end
  end

  configurable(:webhookdb) do
    setting :database_url, ENV.fetch("DATABASE_URL", nil)
    setting :schema, :public
    setting :postmark_inbound_messages_table, :postmark_inbound_message_v1_fixture
    setting :postmark_inbound_messages_secret, "fakesecret-#{SecureRandom.hex(3)}"
    setting :stripe_refunds_table, :stripe_refund_v1_fixture
    setting :stripe_refunds_secret, "fakesecret-#{SecureRandom.hex(3)}"
    setting :stripe_charges_table, :stripe_charge_v1_fixture
    setting :stripe_charges_secret, "fakesecret-#{SecureRandom.hex(3)}"

    after_configured do
      self.connection = Sequel.connect(self.database_url, extensions: [:pg_json])
    end
  end
end
