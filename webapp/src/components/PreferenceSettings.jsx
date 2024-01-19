import api from "../api";
import { t } from "../localization";
import useErrorToast from "../state/useErrorToast";
import useScreenLoader from "../state/useScreenLoader";
import useUser from "../state/useUser";
import FormButtons from "./FormButtons";
import FormSuccess from "./FormSuccess";
import humps from "humps";
import isEmpty from "lodash/isEmpty";
import merge from "lodash/merge";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Form from "react-bootstrap/Form";

export default function PreferenceSettings({
  subscriptions,
  successKey,
  onSubscriptionsSaved,
}) {
  const { showErrorToast } = useErrorToast();
  const { handleUpdateCurrentMember } = useUser();
  const screenLoader = useScreenLoader();
  const [subscriptionsState, setSubscriptionsState] = React.useState(subscriptions);
  const [changes, setChanges] = React.useState({});
  const handleSubscriptionChange = (idx, changedSubscriptionObj) => {
    const newSubscriptions = subscriptionsState;
    newSubscriptions[idx] = changedSubscriptionObj;
    setChanges(
      merge({}, changes, { [changedSubscriptionObj.key]: changedSubscriptionObj.checked })
    );
    setSubscriptionsState(newSubscriptions);
  };

  function handleSubmit(e) {
    e.preventDefault();
    if (isEmpty(changes)) {
      return;
    }
    screenLoader.turnOn();
    api
      .updatePreferences(changes)
      .tap(handleUpdateCurrentMember)
      .then(() => onSubscriptionsSaved())
      .catch((e) => showErrorToast(e, { extract: true }))
      .finally(() => {
        setChanges({});
        screenLoader.turnOff();
      });
  }

  if (isEmpty(subscriptionsState)) {
    return (
      <>
        <h4>{t("preferences:title")}</h4>
        <p>{t("preferences:unavailable")}</p>
      </>
    );
  }
  return (
    <Form onSubmit={handleSubmit}>
      <h4>{t("preferences:title")}</h4>
      {subscriptionsState.map((sub, idx) => (
        <Checkbox
          key={sub.key}
          index={idx}
          subscription={sub}
          onSubscriptionChange={handleSubscriptionChange}
        />
      ))}
      {successKey && (
        <Alert variant="success" className="mt-3 mb-0">
          <FormSuccess message={successKey} className="mb-0" />
        </Alert>
      )}
      <FormButtons variant="success" primaryProps={{ children: t("forms:save") }} />
    </Form>
  );
}

function Checkbox({ index, subscription, onSubscriptionChange }) {
  let { key, checked, editableState } = subscription;
  const decamalizedKey = humps.decamelize(key);
  return (
    <Form.Group className="mb-2">
      <Form.Check
        id={key}
        type="checkbox"
        label={t(`preferences:${decamalizedKey}:title`)}
        checked={checked}
        disabled={editableState !== "on"}
        onChange={(e) => {
          subscription.checked = e.target.checked;
          onSubscriptionChange(index, subscription);
        }}
      />
      <Form.Text>{t(`preferences:${decamalizedKey}:helper_text`)}</Form.Text>
    </Form.Group>
  );
}
