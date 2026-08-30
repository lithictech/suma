import api from "../api.ts";
import Preferences from "../components/Preferences.tsx";
import { t } from "../localization";
import { FeedbackValue, success } from "../modules/feedback.ts";
import useUser from "../state/useUser.ts";
import React from "react";

export default function PreferencesAuthed() {
  const { user, setUser } = useUser();
  const [feedback, setFeedback] = React.useState<FeedbackValue | null>(null);

  function savePrefs(prefs: { subscriptions: Record<string, boolean> }) {
    setFeedback(null);
    return api.updatePreferences(prefs).then((r) => {
      setUser(r.data);
      setFeedback(success(t("preferences.success")));
    });
  }

  return <Preferences user={user!} savePrefs={savePrefs} feedback={feedback} />;
}
