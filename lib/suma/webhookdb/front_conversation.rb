# frozen_string_literal: true

class Suma::Webhookdb::FrontConversation < Suma::Webhookdb::Model(Suma::Webhookdb.front_conversations_table)
end

# Table: front_conversation_v1_fixture
# ----------------------------------------------------------------------------------------------------------------------
# Columns:
#  pk         | bigint                   | PRIMARY KEY DEFAULT nextval('front_conversation_v1_fixture_pk_seq'::regclass)
#  front_id   | text                     | NOT NULL
#  subject    | text                     |
#  status     | text                     |
#  created_at | timestamp with time zone |
#  data       | jsonb                    | NOT NULL
# Indexes:
#  front_conversation_v1_fixture_pkey         | PRIMARY KEY btree (pk)
#  front_conversation_v1_fixture_front_id_key | UNIQUE btree (front_id)
# ----------------------------------------------------------------------------------------------------------------------
