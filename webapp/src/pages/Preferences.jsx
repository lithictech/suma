import PreferenceSettings from "../components/PreferenceSettings";
import useUser from "../state/useUser";
import React from "react";

export default function Preferences() {
  const { user } = useUser();
  return (
    <PreferenceSettings subscriptions={user.preferences?.messagingSubscriptions || []} />
  );
}
