import { t } from "../localization";
import FormButtons from "./FormButtons";
import humps from "humps";
import isEmpty from "lodash/isEmpty";
import merge from "lodash/merge";
import React from "react";
import Form from "react-bootstrap/Form";

export default function PreferenceSettings({ subscriptions }) {
  const [subscriptionState, setSubscriptionState] = React.useState(subscriptions);
  const [changes, setChanges] = React.useState({});
  const handleSubscriptionChange = (idx, changedSubscriptionObj) => {
    const newSubscriptions = subscriptionState;
    newSubscriptions[idx] = changedSubscriptionObj;
    setChanges(
      merge({}, changes, { [changedSubscriptionObj.key]: changedSubscriptionObj.checked })
    );
    setSubscriptionState(newSubscriptions);
  };
  // TODO: Add subscription changes API call and error handling
  // Probably need to call from higher component
  if (isEmpty(subscriptionState)) {
    return (
      <>
        <h4>{t("preferences:title")}</h4>
        <p>{t("preferences:unavailable")}</p>
      </>
    );
  }
  return (
    <Form>
      <h4>{t("preferences:title")}</h4>
      {subscriptionState.map((sub, idx) => (
        <Checkbox
          key={sub.key}
          index={idx}
          subscription={sub}
          onSubscriptionChange={handleSubscriptionChange}
        />
      ))}
      <FormButtons variant="success" primaryProps={{ children: t("forms:save") }} />
    </Form>
  );
}

function Checkbox({ index, subscription, onSubscriptionChange }) {
  let { key, checked, editableState } = subscription;
  const decamalizedKey = humps.decamelize(key);
  return (
    <Form.Group>
      <Form.Check
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
