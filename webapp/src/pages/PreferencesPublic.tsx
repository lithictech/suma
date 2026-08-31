import api from "../api.ts";
import ErrorPage from "../components/ErrorPage.tsx";
import LoadingPage from "../components/LoadingPage.tsx";
import Preferences from "../components/Preferences.tsx";
import { t } from "../localization";
import { extractAppErrorAny, FeedbackValue, success } from "../modules/feedback.ts";
import useAsyncFetch from "../state/useAsyncFetch.ts";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function PreferencesPublic() {
  const [searchParams] = useSearchParams();
  const accessToken = searchParams.get("token");
  const [feedback, setFeedback] = React.useState<FeedbackValue | null>(null);

  const getPreferences = React.useCallback(() => {
    return api
      .getPreferencesPublic({ accessToken })
      .tapCatch((e) => setFeedback(extractAppErrorAny(e)));
  }, [accessToken]);

  const { state, loading, error } = useAsyncFetch<PublicPrefsMember>(getPreferences);

  function savePrefs(prefs: { subscriptions: Record<string, boolean> }) {
    setFeedback(null);
    return api
      .updatePreferencesPublic({ accessToken, ...prefs })
      .then(() => {
        setFeedback(success(t("preferences.success")));
      })
      .catch((e) => setFeedback(extractAppErrorAny(e)));
  }

  if (loading) {
    return <LoadingPage page />;
  }
  if (error) {
    return <ErrorPage variant="home" page />;
  }
  return <Preferences user={state!} savePrefs={savePrefs} feedback={feedback} />;
}
