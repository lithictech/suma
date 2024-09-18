# frozen_string_literal: true

require "suma/api"

class Suma::API::Surveys < Suma::API::V1
  include Suma::API::Entities

  params do
    requires :topic, type: String
    requires :questions, type: Array[JSON] do
      requires :key, type: String
      requires :label, type: String
      requires :format, type: String, values: ["radio", "checkbox", "text"]
      optional :answers, type: Array[JSON] do
        requires :key, type: String
        requires :label, type: String
        requires :value
      end
    end
  end
  post :surveys do
    member = current_member
    db = member.db
    db.transaction do
      survey_id = db[:member_surveys].insert(member_id: member.id, topic: params[:topic])
      params[:questions].each do |q|
        question_id = db[:member_survey_questions].insert(
          survey_id:,
          key: q.fetch(:key),
          label: q.fetch(:label),
          format: q.fetch(:format),
        )
        q[:answers]&.each do |a|
          value_col = case q.fetch(:format)
            when "radio", "checkbox"
              :value_boolean
            when "text"
              :value_text
          end
          db[:member_survey_answers].insert(
            question_id:,
            key: a.fetch(:key),
            label: a.fetch(:label),
            value_col => a.fetch(:value),
          )
        end
      end
    end
    status 200
    present member, with: CurrentMemberEntity, env:
  end
end
