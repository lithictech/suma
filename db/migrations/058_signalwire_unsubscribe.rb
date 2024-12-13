# frozen_string_literal: true

Sequel.migration do
  up do
    if ENV["RACK_ENV"] == "test"
      run <<~SQL
        CREATE TABLE signalwire_message_v1_fixture (
          pk bigserial PRIMARY KEY,
          signalwire_id text UNIQUE NOT NULL,
          date_created timestamptz,
          date_sent timestamptz,
          date_updated timestamptz,
          direction text,
          "from" text,
          status text,
          "to" text,
          data jsonb NOT NULL
        );
        CREATE INDEX IF NOT EXISTS svi_fixture_date_created_idx ON signalwire_message_v1_fixture (date_created);
        CREATE INDEX IF NOT EXISTS svi_fixture_date_sent_idx ON signalwire_message_v1_fixture (date_sent);
        CREATE INDEX IF NOT EXISTS svi_fixture_date_updated_idx ON signalwire_message_v1_fixture (date_updated);
        CREATE INDEX IF NOT EXISTS svi_fixture_from_idx ON signalwire_message_v1_fixture ("from");
        CREATE INDEX IF NOT EXISTS svi_fixture_to_idx ON signalwire_message_v1_fixture ("to");
      SQL
    end
  end

  down do
    run("DROP TABLE signalwire_message_v1_fixture") if ENV["RACK_ENV"] == "test"
  end
end
