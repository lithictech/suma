/**
 * Return the keys of survey questions that offer answers
 * but have none of them selected.
 * @param {SurveySpec} survey
 * @param {function(SurveySpecQuestion, SurveySpecAnswer): *} getAnswer
 * @return {Array<string>}
 */
export function findUnansweredQuestionKeys(survey, getAnswer) {
  return survey.questions
    .filter(
      (question) =>
        question.answers.length > 0 &&
        !question.answers.some((answer) => getAnswer(question, answer))
    )
    .map((question) => question.key);
}
