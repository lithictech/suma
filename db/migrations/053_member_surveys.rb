# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:member_surveys) do
      primary_key :id
      foreign_key :member_id, :members, null: false
      text :topic, null: false
      timestamptz :created_at, null: false, default: Sequel.function(:now)
    end

    create_table(:member_survey_questions) do
      primary_key :id
      foreign_key :survey_id, :member_surveys, null: false
      text :key, null: false
      text :label, null: false
      text :format, null: false
    end

    create_table(:member_survey_answers) do
      primary_key :id
      foreign_key :question_id, :member_survey_questions, null: false
      text :key, null: false
      text :label, null: false
      boolean :value_boolean
      text :value_text
    end

    from(:member_surveys).insert(
      [:member_id, :created_at, :topic],
      from(:member_key_values).select(:member_id, :created_at, :key),
    )

    drop_table(:member_key_values)
  end

  down do
    create_table(:member_key_values) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      foreign_key :member_id, :members, null: false, on_delete: :cascade
      text :key, null: false
      text :value_string, null: true

      index [:key, :member_id], name: :unique_member_key_idx, unique: true
    end

    from(:member_key_values).insert(
      [:member_id, :created_at, :key],
      from(:member_surveys).select(:member_id, :created_at, :topic),
    )

    drop_table(:member_survey_answers)
    drop_table(:member_survey_questions)
    drop_table(:member_surveys)
  end
end
