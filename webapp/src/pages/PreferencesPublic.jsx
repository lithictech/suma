import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FormSuccess from "../components/FormSuccess";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import Preferences from "../components/Preferences";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import useErrorToast from "../state/useErrorToast";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function PreferencesPublic() {
  const [searchParams] = useSearchParams();
  const accessToken = searchParams.get("token");
  const { enqueueErrorToast } = useErrorToast();
  const successView = useToggle(false);

  const getPreferences = React.useCallback(() => {
    return api.getPreferencesPublic({ accessToken }).catch((e) => enqueueErrorToast(e));
  }, [accessToken, enqueueErrorToast]);
  const { state, loading, error } = useAsyncFetch(getPreferences, { pickData: true });

  function handleApiSubmit(prefs) {
    return api.updatePreferencesPublic({ accessToken, ...prefs });
  }

  if (loading) {
    return <PageLoader overlay />;
  }
  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (successView.isOn) {
    return <FormSuccess message={"preferences:success"} />;
  }
  return (
    <Preferences
      user={state}
      onApiSubmit={handleApiSubmit}
      onSaved={() => successView.turnOn()}
    />
  );
}
