import { findUnansweredQuestionKeys } from "./findUnansweredQuestionKeys";

const survey = {
  topic: "utilities_waitlist",
  questions: [
    {
      key: "entity_type",
      format: "radio",
      answers: [{ key: "community" }, { key: "for_profit" }],
    },
    {
      key: "utility_providers",
      format: "checkbox",
      answers: [{ key: "comcast" }, { key: "pge" }],
    },
  ],
};

function answersGetter(state) {
  return (question, answer) => state[`${question.key}:${answer.key}`];
}

it("returns every question when nothing is selected", () => {
  expect(findUnansweredQuestionKeys(survey, answersGetter({}))).toEqual([
    "entity_type",
    "utility_providers",
  ]);
});
it("returns only the questions without a selected answer", () => {
  const getAnswer = answersGetter({ "entity_type:for_profit": true });
  expect(findUnansweredQuestionKeys(survey, getAnswer)).toEqual(["utility_providers"]);
});
it("treats unchecked checkboxes as unanswered", () => {
  const getAnswer = answersGetter({
    "entity_type:community": true,
    "utility_providers:comcast": false,
  });
  expect(findUnansweredQuestionKeys(survey, getAnswer)).toEqual(["utility_providers"]);
});
it("returns nothing when every question has an answer", () => {
  const getAnswer = answersGetter({
    "entity_type:community": true,
    "utility_providers:pge": true,
  });
  expect(findUnansweredQuestionKeys(survey, getAnswer)).toEqual([]);
});
it("returns nothing for a survey with no questions", () => {
  expect(
    findUnansweredQuestionKeys({ topic: "mobility_waitlist", questions: [] }, () => null)
  ).toEqual([]);
});
