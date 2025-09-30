# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:support_tickets) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :sender_name, null: false, default: ""
      foreign_key :sender_id, :members, null: true, on_delete: :set_null
      text :subject, null: false
      text :body, null: false

      text :external_id, null: true, unique: true
      text :front_id, null: true
    end

    create_join_table(
      {support_ticket_id: :support_tickets, uploaded_file_id: :uploaded_files},
      name: :support_tickets_uploaded_files,
    )

    rename_table(:organization_membership_verification_notes, :support_notes)

    create_join_table(
      {
        note_id: :support_notes,
        verification_id: :organization_membership_verifications,
      },
      name: :support_notes_organization_membership_verifications,
    )
    create_join_table(
      {
        note_id: :support_notes,
        member_id: :members,
      },
      name: :support_notes_members,
    )
    from(:support_notes).each do |row|
      from(:support_notes_organization_membership_verifications).insert(
        note_id: row[:id],
        verification_id: row[:verification_id],
      )
    end

    alter_table(:support_notes) do
      drop_column :verification_id
    end
  end
end
