# frozen_string_literal: true

class Suma::Webhookdb::FrontMessage < Suma::Webhookdb::Model(Suma::Webhookdb.front_messages_table)
end

# Table: front_message_v1_fixture
# ----------------------------------------------------------------------------------------------------------------------------
# Columns:
#  pk                    | bigint                   | PRIMARY KEY DEFAULT nextval('front_message_v1_fixture_pk_seq'::regclass)
#  front_id              | text                     | NOT NULL
#  type                  | text                     |
#  front_conversation_id | text                     |
#  created_at            | timestamp with time zone |
#  data                  | jsonb                    | NOT NULL
# Indexes:
#  front_message_v1_fixture_pkey         | PRIMARY KEY btree (pk)
#  front_message_v1_fixture_front_id_key | UNIQUE btree (front_id)
# ----------------------------------------------------------------------------------------------------------------------------
