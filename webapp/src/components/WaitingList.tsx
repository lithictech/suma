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
import Button from "../ui/Button";
import Form from "../ui/Form";
import FormCheck from "../ui/FormCheck";
import FormLabel from "../ui/FormLabel";
import React from "react";

interface SurveySpecAnswer {
  /** Identify this possible answer within the question. */
  key: string;
  /** Label for this answer. */
  labelKey: string;
}

interface SurveySpecQuestion {
  /** Persistent identifier for this question within the survey. */
  key: string;
  /** i18n key for this prompt. */
  labelKey: string;
  /** Format of this question. */
  format: "checkbox" | "radio";
  /** Potential answers for multiple-choice format questions. */
  answers: SurveySpecAnswer[];
}

interface SurveySpec {
  /** What is the name of the survey? */
  topic: string;
  questions: SurveySpecQuestion[];
}

interface SurveyAnswers {
  replaceAnswers: (
    question: SurveySpecQuestion,
    answer: SurveySpecAnswer,
    value: any
  ) => void;
  getAnswer: (question: SurveySpecQuestion, answer: SurveySpecAnswer) => any;
  setAnswer: (question: SurveySpecQuestion, answer: SurveySpecAnswer, value: any) => void;
  answerKey: (question: SurveySpecQuestion, answer: SurveySpecAnswer) => string;
}

interface WaitingListProps {
  survey: SurveySpec;
  title: React.ReactNode;
  text: React.ReactNode;
}

export default function WaitingList({ survey, title, text }: WaitingListProps) {
  const { user, setUser } = useUser();
  const { showErrorToast } = useErrorToast();
  const [loading, setLoading] = React.useState(true);
  const [justFinished, setJustFinished] = React.useState(false);
  const surveyAnswers = useSurveyAnswers();

  const { loadLanguageFile } = useI18n();
  useMountEffect(() => {
    loadLanguageFile("surveys").then(() => setLoading(false));
  });
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    const body = buildApiSurveyResponse(survey, surveyAnswers);
    api
      .completeSurvey(body)
      .then((r: any) => {
        setUser(r.data);
        setJustFinished(true);
      })
      .catch((e: any) => {
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

interface WaitlistFormProps {
  title: React.ReactNode;
  text: React.ReactNode;
  survey: SurveySpec;
  surveyAnswers: SurveyAnswers;
  onSubmit: (e: React.FormEvent) => void;
}

function WaitlistForm({
  title,
  text,
  survey,
  surveyAnswers,
  onSubmit,
}: WaitlistFormProps) {
  const inputs: React.ReactNode[] = [];
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
            {i18n.t("surveys.join_waitlist")}
          </Button>
        </div>
      </Form>
    </>
  );
}

function AlreadyFinished({
  title,
  text,
}: {
  title: React.ReactNode;
  text: React.ReactNode;
}) {
  return (
    <>
      <h2>{title}</h2>
      {text}
      <hr />
      <p className="text-center lead">{i18n.t("surveys.waitlisted_already")}</p>
    </>
  );
}

function JustFinished() {
  return (
    <div className="d-flex flex-column align-items-center mt-3">
      <div>
        <AnimatedCheckmark />
      </div>
      <p className="mt-4 mb-0 text-center lead checkmark__text">
        {i18n.t("surveys.waitlist_joined")}
      </p>
      <div className="button-stack mt-4 w-100">
        <Button variant="outline" href="/dashboard" as={RLink}>
          {t("common.go_home")}
        </Button>
      </div>
    </div>
  );
}

function SurveyDivider() {
  return <hr className="my-4" />;
}

function SurveyCheckboxQuestion({
  question,
  surveyAnswers,
}: {
  question: SurveySpecQuestion;
  surveyAnswers: SurveyAnswers;
}) {
  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLInputElement>, answer: SurveySpecAnswer) => {
      if (question.format === "radio") {
        surveyAnswers.replaceAnswers(question, answer, true);
      } else {
        surveyAnswers.setAnswer(question, answer, (e.target as HTMLInputElement).checked);
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
            onClick={(e) => handleClick(e as React.MouseEvent<HTMLInputElement>, answer)}
          />
        );
      })}
    </div>
  );
}

function useSurveyAnswers(): SurveyAnswers {
  const [state, setState] = React.useState<Record<string, any>>({});
  const answerKey = React.useCallback(
    (question: SurveySpecQuestion, answer: SurveySpecAnswer) =>
      `${question.key}:${answer.key}`,
    []
  );
  const getAnswer = React.useCallback(
    (question: SurveySpecQuestion, answer: SurveySpecAnswer) => {
      return state[answerKey(question, answer)];
    },
    [answerKey, state]
  );
  const setAnswer = React.useCallback(
    (question: SurveySpecQuestion, answer: SurveySpecAnswer, value: any) => {
      const newState = { ...state, [answerKey(question, answer)]: value };
      setState(newState);
    },
    [answerKey, state]
  );
  const replaceAnswers = React.useCallback(
    (question: SurveySpecQuestion, answer: SurveySpecAnswer, value: any) => {
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
 */
function buildApiSurveyResponse(survey: SurveySpec, surveyAnswers: SurveyAnswers) {
  const body: { topic: string; questions: any[] } = {
    topic: survey.topic,
    questions: [],
  };
  survey.questions.forEach((question) => {
    const { key, labelKey, format, answers } = question;
    const ranswers: any[] = [];
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
