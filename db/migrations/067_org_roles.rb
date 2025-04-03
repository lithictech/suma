# frozen_string_literal: true

Sequel.migration do
  change do
    create_join_table({role_id: :roles, organization_id: :organizations}, name: :roles_organizations)
    alter_table(:member_activities) do
      add_index [:subject_id, :subject_type]
      add_column(
        :subject_id_int,
        :integer,
        generated_always_as: Sequel.case(
          {Sequel.function(:regexp_match, :subject_id, '^\d+$') !~ nil => Sequel.cast(:subject_id, :integer)},
          nil,
        ),
      )
      add_index [:subject_id_int, :subject_type]
    end
  end
end
