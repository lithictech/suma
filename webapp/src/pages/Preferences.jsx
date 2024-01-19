import PreferenceSettings from "../components/PreferenceSettings";
import useUser from "../state/useUser";
import React from "react";

export default function Preferences() {
  const { user } = useUser();
  const [successKey, setSuccessKey] = React.useState();

  return (
    <PreferenceSettings
      subscriptions={user.preferences?.messagingSubscriptions}
      successKey={successKey}
      onSubscriptionsSaved={() => setSuccessKey("preferences:success")}
    />
  );
}
