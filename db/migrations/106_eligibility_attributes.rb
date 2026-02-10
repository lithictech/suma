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

      column :search_content, :text
      column :search_embedding, "vector(384)"
      column :search_hash, :text
      index Sequel.function(:to_tsvector, "english", :search_content),
            name: :eligibility_attributes_search_content_tsvector_index,
            type: :gin
    end

    create_table(:eligibility_assignments) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      foreign_key :created_by_id, :members, on_delete: :set_null

      foreign_key :attribute_id, :eligibility_attributes, null: false, index: true, on_delete: :cascade

      foreign_key :member_id, :members, on_delete: :cascade
      foreign_key :organization_id, :organizations, on_delete: :cascade
      foreign_key :role_id, :roles, on_delete: :cascade

      constraint :unambiguous_assignee,
                 Sequel.unambiguous_constraint([:member_id, :organization_id, :role_id])

      index [:attribute_id, :member_id], unique: true, where: Sequel[:member_id] !~ nil
      index [:attribute_id, :organization_id], unique: true, where: Sequel[:member_id] !~ nil
      index [:attribute_id, :role_id], unique: true, where: Sequel[:member_id] !~ nil

      column :search_content, :text
      column :search_embedding, "vector(384)"
      column :search_hash, :text
      index Sequel.function(:to_tsvector, "english", :search_content),
            name: :eligibility_assignments_search_content_tsvector_index,
            type: :gin
    end

    create_view :eligibility_member_assignments, Sequel.lit(<<~SQL)
      WITH RECURSIVE attr_expanded AS (
          SELECT id AS attribute_id, id AS root_attribute_id, 0 as depth
          FROM eligibility_attributes

          UNION ALL

          SELECT e.parent_id AS attribute_id, a.root_attribute_id, a.depth + 1 as depth
          FROM attr_expanded a
              JOIN eligibility_attributes e
              ON e.id = a.attribute_id
          WHERE e.parent_id IS NOT NULL
      ), base AS (
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
      )
      SELECT DISTINCT b.member_id, e.attribute_id, b.source_type, b.source_ids, e.depth
      FROM base b
      JOIN attr_expanded e
      ON e.root_attribute_id = b.attribute_id;
    SQL

    create_table(:eligibility_expressions) do
      primary_key :id

      foreign_key :left_id, :eligibility_expressions, on_delete: :cascade
      foreign_key :right_id, :eligibility_expressions, on_delete: :cascade
      text :operator, null: false, default: "AND"
      constraint :valid_operator, Sequel[:operator] =~ ["AND", "OR"]

      foreign_key :attribute_id, :eligibility_attributes, on_delete: :cascade

      constraint :unambiguous_node_type,
                 Sequel.unambiguous_constraint([:left_id, :attribute_id], allow_all_null: true)
    end

    create_table(:eligibility_requirements) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      foreign_key :created_by_id, :members, on_delete: :set_null

      foreign_key :program_id, :programs, index: true, on_delete: :cascade
      foreign_key :payment_trigger_id, :payment_triggers, index: true, on_delete: :cascade
      constraint :unambiguous_resource,
                 Sequel.unambiguous_constraint([:program_id, :payment_trigger_id])

      foreign_key :expression_id, :eligibility_expressions, on_delete: :cascade

      column :cached_attribute_ids, "integer[]", index: true, null: false
      text :cached_expression_string, null: false

      column :search_content, :text
      column :search_embedding, "vector(384)"
      column :search_hash, :text
      index Sequel.function(:to_tsvector, "english", :search_content),
            name: :eligibility_requirements_search_content_tsvector_index,
            type: :gin
    end
  end
end
