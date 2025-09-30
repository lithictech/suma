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
        note_id: row.fetch(:id),
        verification_id: row.fetch(:verification_id),
      )
    end

    alter_table(:support_notes) do
      rename_column :verification_id, :legacy_verification_id
      set_column_allow_null :legacy_verification_id
    end

    from(:members).exclude(note: "").each do |row|
      notes = from(:support_notes).returning(:id).insert(content: row.fetch(:note), created_at: row[:updated_at])
      note = notes.first
      from(:support_notes_members).insert(member_id: row.fetch(:id), note_id: note.fetch(:id))
    end

    alter_table(:members) do
      rename_column :note, :legacy_note
    end
  end

  down do
    drop_table(:support_tickets_uploaded_files)
    drop_table(:support_tickets)
    rename_table(:support_notes, :organization_membership_verification_notes)
    drop_table(:support_notes_organization_membership_verifications)
    drop_table(:support_notes_members)
    from(:organization_membership_verification_notes).where(legacy_verification_id: nil).delete
    alter_table(:organization_membership_verification_notes) do
      set_column_not_null :legacy_verification_id
      rename_column :legacy_verification_id, :verification_id
    end
    alter_table(:members) do
      rename_column :legacy_note, :note
    end
  end
end
