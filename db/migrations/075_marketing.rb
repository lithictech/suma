# frozen_string_literal: true

require "sequel/all_or_none_constraint"

Sequel.migration do
  change do
    create_table(:marketing_lists) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :name, null: false
      boolean :managed, null: false, default: false

      column :search_content, :text
      column :search_embedding, "vector(384)"
      column :search_hash, :text
      index Sequel.function(:to_tsvector, "english", :search_content),
            name: :marketing_lists_search_content_tsvector_index,
            type: :gin
    end

    create_join_table(
      {marketing_list_id: :marketing_lists, member_id: :members},
      name: :marketing_lists_members,
    )

    create_table(:marketing_sms_campaigns) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :sent_at

      text :name, null: false

      foreign_key :body_id, :translated_texts, null: false

      foreign_key :created_by_id, :members, on_delete: :set_null

      column :search_content, :text
      column :search_embedding, "vector(384)"
      column :search_hash, :text
      index Sequel.function(:to_tsvector, "english", :search_content),
            name: :marketing_sms_campaigns_search_content_tsvector_index,
            type: :gin
    end

    create_join_table(
      {list_id: :marketing_lists, sms_campaign_id: :marketing_sms_campaigns},
      name: :marketing_lists_sms_campaigns,
    )

    create_table(:marketing_sms_dispatches) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      foreign_key :member_id, :members, null: false
      foreign_key :sms_campaign_id, :marketing_sms_campaigns, null: false
      unique [:member_id, :sms_campaign_id]
      timestamptz :sent_at
      text :transport_message_id
      Sequel.all_or_none_constraint([:sent_at, :transport_message_id])

      column :search_content, :text
      column :search_embedding, "vector(384)"
      column :search_hash, :text
      index Sequel.function(:to_tsvector, "english", :search_content),
            name: :marketing_sms_dispatches_search_content_tsvector_index,
            type: :gin
    end
  end
end
