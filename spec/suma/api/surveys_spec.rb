# frozen_string_literal: true

require "suma/api/behaviors"
require "suma/api/surveys"

RSpec.describe Suma::API::Surveys, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.create }

  before(:each) do
    login_as(member)
  end

  describe "POST /v1/surveys" do
    it "creates the survey with the given information" do
      body = {
        topic: "bridge_of_death",
        questions: [
          {
            key: "name",
            label: "What is your name?",
            format: "radio",
            answers: [
              {key: "robin", label: "Robin", value: true},
            ],
          },
          {
            key: "quest",
            label: "What is your quest?",
            format: "checkbox",
            answers: [
              {key: "grail", label: "Find the Holy Grail", value: true},
              {key: "glory", label: "seek glory", value: true},
            ],
          },
          {
            key: "capital",
            label: "What is the capital of Assyria?",
            format: "text",
            answers: [
              {key: "", label: "", value: "Huh?"},
            ],
          },
          {
            key: "never_asked",
            label: "???",
            format: "checkbox",
          },
        ],
      }

      post "/v1/surveys", **body
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(finished_survey_topics: ["bridge_of_death"])

      db = Suma::Member.db
      survey = db[:member_surveys].where(member_id: member.id).first
      expect(survey).to include(topic: "bridge_of_death")
      questions = db[:member_survey_questions].all
      expect(questions).to contain_exactly(
        include(key: "name", label: "What is your name?", format: "radio"),
        include(key: "quest", label: "What is your quest?", format: "checkbox"),
        include(key: "capital", label: "What is the capital of Assyria?", format: "text"),
        include(key: "never_asked"),
      )
      answers = db[:member_survey_answers].all
      expect(answers).to include(
        include(key: "robin", label: "Robin", value_boolean: true, value_text: nil),
        include(key: "grail", label: "Find the Holy Grail", value_boolean: true),
        include(key: "glory", label: "seek glory", value_boolean: true),
        include(key: "", label: "", value_boolean: nil, value_text: "Huh?"),
      )
    end
  end
end
