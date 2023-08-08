# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:anon_proxy_member_contacts) do
      # Originally the idea is that, the use of the phone number is implied by the relay.
      # But it turns out this is just more confusing, and doesn't add anything to the modeling
      # or future flexibility, so name the contact fields the same as the relay transports.
      rename_column :phone, :sms
    end

    if ENV["RACK_ENV"] == "test"
      run <<~SQL
        DROP TABLE IF EXISTS public.plivo_sms_inbound_v1_fixture;
        CREATE TABLE public.plivo_sms_inbound_v1_fixture (
          pk bigserial PRIMARY KEY,
          plivo_message_uuid text UNIQUE NOT NULL,
          row_inserted_at timestamptz,
          from_number text,
          to_number text,
          data jsonb NOT NULL
        );
        CREATE INDEX IF NOT EXISTS svi_fixture_row_inserted_at_idx ON public.plivo_sms_inbound_v1_fixture (row_inserted_at);
        CREATE INDEX IF NOT EXISTS svi_fixture_from_number_idx ON public.plivo_sms_inbound_v1_fixture (from_number);
        CREATE INDEX IF NOT EXISTS svi_fixture_to_number_idx ON public.plivo_sms_inbound_v1_fixture (to_number);
      SQL
    end
  end
end
