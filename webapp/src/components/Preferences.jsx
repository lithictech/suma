import { t } from "../localization";
import useErrorToast from "../state/useErrorToast";
import useScreenLoader from "../state/useScreenLoader";
import FormButtons from "./FormButtons";
import has from "lodash/has";
import React from "react";
import Form from "react-bootstrap/Form";

export default function Preferences({ user, onApiSubmit, children, onSaved }) {
  const { showErrorToast } = useErrorToast();
  const screenLoader = useScreenLoader();
  const [subscriptions, setSubscriptions] = React.useState({});

  function handleSubmit(e) {
    e.preventDefault();
    screenLoader.turnOn();
    onApiSubmit({ subscriptions })
      .then((r) => onSaved(r))
      .catch((e) => showErrorToast(e, { extract: true }))
      .finally(() => {
        setSubscriptions({});
        screenLoader.turnOff();
      });
  }

  return (
    <Form onSubmit={handleSubmit}>
      <h4>{t("preferences:title")}</h4>
      <p>{t("preferences:intro")}</p>
      {user.preferences.subscriptions.map((sub, idx) => {
        const optedIn = has(subscriptions, sub.key)
          ? subscriptions[sub.key]
          : sub.optedIn;
        return (
          <Subscription
            key={sub.key}
            index={idx}
            subscriptionKey={sub.key}
            optedIn={optedIn}
            editableState={sub.editableState}
            onCheckChange={(ch) =>
              setSubscriptions((prev) => {
                return { ...prev, [sub.key]: ch };
              })
            }
          />
        );
      })}
      {children}
      <FormButtons variant="success" primaryProps={{ children: t("forms:save") }} />
    </Form>
  );
}

function Subscription({ subscriptionKey, optedIn, editableState, onCheckChange }) {
  return (
    <Form.Group className="mt-4">
      {editableState === "hidden" ? (
        <p className="mb-0">{t(`preferences:${subscriptionKey}:title`)}</p>
      ) : (
        <Form.Check
          id={subscriptionKey}
          type="checkbox"
          label={t(`preferences:${subscriptionKey}:title`)}
          checked={optedIn}
          disabled={editableState !== "on"}
          onChange={(e) => onCheckChange(e.target.checked)}
        />
      )}
      <Form.Text>{t(`preferences:${subscriptionKey}:helper_text`)}</Form.Text>
    </Form.Group>
  );
}
