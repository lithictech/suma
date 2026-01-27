# frozen_string_literal: true

require "sequel/all_or_none_constraint"
require "sequel/unambiguous_constraint"

Sequel.migration do
  change do
    create_table(:eligibility_attributes) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :name, null: false, unique: true
      text :description, null: false, default: ""

      foreign_key :parent_id, :eligibility_attributes, null: true, index: true
    end

    create_table(:eligibility_assignments) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :attribute_id, :eligibility_attributes, null: false, index: true, on_delete: :cascade

      foreign_key :member_id, :members, on_delete: :cascade
      foreign_key :organization_id, :organizations, on_delete: :cascade
      foreign_key :role_id, :roles, on_delete: :cascade

      constraint :unambiguous_assignee,
                 Sequel.unambiguous_constraint([:member_id, :organization_id, :role_id])

      index [:attribute_id, :member_id], unique: true, where: Sequel[:member_id] !~ nil
      index [:attribute_id, :organization_id], unique: true, where: Sequel[:member_id] !~ nil
      index [:attribute_id, :role_id], unique: true, where: Sequel[:member_id] !~ nil
    end

    create_view :eligibility_member_assignments, Sequel.lit(<<~SQL)
      SELECT DISTINCT member_id, attribute_id, source_type, source_ids
      FROM (
            SELECT member_id, attribute_id, 'member' AS source_type, ARRAY[member_id] AS source_ids
            FROM eligibility_assignments ea
            WHERE member_id IS NOT NULL
            UNION ALL
            SELECT rm.member_id, ea.attribute_id, 'role' AS source, ARRAY[rm.role_id] AS source_ids
            FROM eligibility_assignments ea
                INNER JOIN roles_members rm
                ON rm.role_id = ea.role_id
            UNION ALL
            SELECT om.member_id, ea.attribute_id, 'membership' AS source, ARRAY[om.id] AS source_ids
            FROM eligibility_assignments ea
                INNER JOIN organization_memberships om
                ON om.verified_organization_id = ea.organization_id
            UNION ALL
            SELECT omr.member_id, ea.attribute_id, 'organization_role' AS source, ARRAY[omr.organization_id, omr.role_id] AS source_ids
            FROM eligibility_assignments ea
                INNER JOIN (
                    SELECT ro.role_id as role_id, om.member_id as member_id, om.verified_organization_id as organization_id
                    FROM organization_memberships om
                    JOIN roles_organizations ro
                    ON ro.organization_id = om.verified_organization_id
                ) omr
                ON omr.role_id = ea.role_id
      ) t;
    SQL

    create_table(:eligibility_expressions) do
      primary_key :id

      foreign_key :left_id, :eligibility_expressions, on_delete: :cascade
      foreign_key :right_id, :eligibility_expressions, on_delete: :cascade
      text :operator, null: false, default: ""
      constraint :valid_operator, Sequel[:operator] =~ ["AND", "OR", ""]

      foreign_key :attribute_id, :eligibility_attributes, on_delete: :cascade

      constraint :unambiguous_node_type,
                 Sequel.unambiguous_constraint([:left_id, :attribute_id], allow_all_null: true)
    end

    create_table(:eligibility_requirements) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :program_id, :programs, index: true, on_delete: :cascade
      foreign_key :payment_trigger_id, :payment_triggers, index: true, on_delete: :cascade
      constraint :unambiguous_resource,
                 Sequel.unambiguous_constraint([:program_id, :payment_trigger_id])

      foreign_key :expression_id, :eligibility_expressions, on_delete: :cascade
    end
  end
end
