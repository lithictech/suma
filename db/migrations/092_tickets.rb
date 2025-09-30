# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:support_tickets) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :sender_name, null: false, default: ""
      foreign_key :sender_id, :members, null: true, on_delete: :set_null
      text :subject, null: false
      text :body, null: false

      text :front_message_id, null: true
    end

    create_join_table(
      {support_ticket_id: :support_tickets, uploaded_file_id: :uploaded_files},
      name: :support_tickets_uploaded_files,
    )
  end
end
