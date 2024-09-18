import api from "../api";
import AnimatedCheckmark from "../components/AnimatedCheckmark";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import { t } from "../localization";
import i18n from "../localization/i18n";
import useI18n from "../localization/useI18n";
import useMountEffect from "../shared/react/useMountEffect";
import useErrorToast from "../state/useErrorToast";
import useUser from "../state/useUser";
import React from "react";
import { FormCheck, FormLabel } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Form from "react-bootstrap/Form";

/**
 * @param {SurveySpec} survey
 * @param {string} title
 * @param {string} text
 */
export default function WaitingList({ survey, title, text }) {
  const { user, setUser } = useUser();
  const { showErrorToast } = useErrorToast();
  const [loading, setLoading] = React.useState(true);
  const [justFinished, setJustFinished] = React.useState(false);
  const surveyAnswers = useSurveyAnswers();

  const { loadLanguageFile } = useI18n();
  useMountEffect(() => {
    loadLanguageFile("surveys").then(() => setLoading(false));
  });
  const handleSubmit = (e) => {
    e.preventDefault();
    setLoading(true);
    const body = buildApiSurveyResponse(survey, surveyAnswers);
    api
      .completeSurvey(body)
      .then((r) => {
        setUser(r.data);
        setJustFinished(true);
      })
      .catch((e) => {
        showErrorToast(e, { extract: true });
      })
      .finally(() => setLoading(false));
  };
  if (loading) {
    return <PageLoader buffered />;
  }
  if (justFinished) {
    return <JustFinished />;
  }
  if (user.finishedSurveyTopics.includes(survey.topic)) {
    return <AlreadyFinished title={title} text={text} />;
  }
  return (
    <WaitlistForm
      title={title}
      text={text}
      survey={survey}
      surveyAnswers={surveyAnswers}
      onSubmit={handleSubmit}
    />
  );
}

/**
 * @param {string} title
 * @param {string} text
 * @param {SurveySpec} survey
 * @param {SurveyAnswers} surveyAnswers
 * @param {function} onSubmit
 */
function WaitlistForm({ title, text, survey, surveyAnswers, onSubmit }) {
  const inputs = [];
  survey.questions.forEach((question) => {
    const key = question.key;
    inputs.push(<SurveyDivider key={`${key}-divider`} />);
    if (["checkbox", "radio"].includes(question.format)) {
      inputs.push(
        <SurveyCheckboxQuestion
          key={key}
          question={question}
          surveyAnswers={surveyAnswers}
        />
      );
    } else {
      console.error("unknown survey question format", key);
    }
  });
  return (
    <>
      <h2>{title}</h2>
      {text}
      <Form noValidate onSubmit={onSubmit}>
        {inputs}
        <div className="button-stack mt-4">
          <Button type="submit" variant="primary">
            {i18n.t("surveys:join_waitlist")}
          </Button>
        </div>
      </Form>
    </>
  );
}

function AlreadyFinished({ title, text }) {
  return (
    <>
      <h2>{title}</h2>
      {text}
      <hr />
      <p className="text-center lead">{i18n.t("surveys:waitlisted_already")}</p>
    </>
  );
}

function JustFinished() {
  return (
    <div className="d-flex flex-column align-items-center mt-3">
      <div>
        <AnimatedCheckmark scale={2} />
      </div>
      <p className="mt-4 mb-0 text-center lead checkmark__text">
        {i18n.t("surveys:waitlist_joined")}
      </p>
      <div className="button-stack mt-4 w-100">
        <Button variant="outline-primary" href="/dashboard" as={RLink}>
          {t("common:go_home")}
        </Button>
      </div>
    </div>
  );
}

function SurveyDivider() {
  return <hr className="my-4" />;
}

/**
 * @param {SurveySpecQuestion} question
 * @param {SurveyAnswers} surveyAnswers
 */
function SurveyCheckboxQuestion({ question, surveyAnswers }) {
  const handleClick = React.useCallback(
    (e, answer) => {
      if (question.format === "radio") {
        surveyAnswers.replaceAnswers(question, answer, true);
      } else {
        surveyAnswers.setAnswer(question, answer, e.target.checked);
      }
    },
    [question, surveyAnswers]
  );
  return (
    <div>
      <FormLabel>{i18n.t(question.labelKey)}</FormLabel>
      {question.answers.map((answer) => {
        const id = surveyAnswers.answerKey(question, answer);
        return (
          <FormCheck
            key={id}
            id={id}
            name={question.key}
            label={i18n.t(answer.labelKey)}
            type={question.format}
            checked={Boolean(surveyAnswers.getAnswer(question, answer))}
            onClick={(e) => handleClick(e, answer)}
          />
        );
      })}
    </div>
  );
}

/**
 * @typedef SurveyAnswers
 * @property {function} replaceAnswers
 * @property {function} getAnswer
 * @property {function} setAnswer
 */

/**
 * @returns {SurveyAnswers}
 */
function useSurveyAnswers() {
  const [state, setState] = React.useState({});
  const answerKey = React.useCallback(
    (question, answer) => `${question.key}:${answer.key}`,
    []
  );
  const getAnswer = React.useCallback(
    (question, answer) => {
      return state[answerKey(question, answer)];
    },
    [answerKey, state]
  );
  const setAnswer = React.useCallback(
    (question, answer, value) => {
      const newState = { ...state, [answerKey(question, answer)]: value };
      setState(newState);
    },
    [answerKey, state]
  );
  const replaceAnswers = React.useCallback(
    (question, answer, value) => {
      const newState = { ...state };
      question.answers.forEach((a2) => {
        delete newState[answerKey(question, a2)];
      });
      newState[answerKey(question, answer)] = value;
      setState(newState);
    },
    [answerKey, state]
  );

  const result = React.useMemo(
    () => ({ getAnswer, setAnswer, replaceAnswers, answerKey }),
    [getAnswer, replaceAnswers, setAnswer, answerKey]
  );
  return result;
}

/**
 * Given frontend-compatible survey objects, return something
 * that can be POSTED to the API.
 * @param {SurveySpec} survey
 * @param {SurveyAnswers} surveyAnswers
 * @return {object}
 */
function buildApiSurveyResponse(survey, surveyAnswers) {
  const body = { topic: survey.topic, questions: [] };
  survey.questions.forEach((question) => {
    const { key, labelKey, format, answers } = question;
    const ranswers = [];
    body.questions.push({ key, label: i18n.t(labelKey), format, answers: ranswers });
    answers.forEach((answer) => {
      const value = surveyAnswers.getAnswer(question, answer);
      if (value) {
        ranswers.push({
          key: answer.key,
          label: i18n.t(answer.labelKey),
          value,
        });
      }
    });
  });
  return body;
}

/**
 * @typedef SurveySpec
 * @property {string} topic What is the name of the survey?
 * @property {Array<SurveySpecQuestion>} questions
 */

/**
 * @typedef SurveySpecQuestion
 * @property {string} key Persistent identifier for this question within the survey.
 * @property {string} labelKey i18n key for this prompt.
 * @property {('checkbox'|'radio')} format Format of this question.
 * @property {Array<SurveySpecAnswer>} answers Potential answers for multiple-choice format questions.
 */

/**
 * @typedef SurveySpecAnswer
 * @property {string} key Identify this possible answer within the question.
 * @property {string} labelKey Label for this answer.
 */
