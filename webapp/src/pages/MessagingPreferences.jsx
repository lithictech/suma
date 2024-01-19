import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FormSuccess from "../components/FormSuccess";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import PreferenceSettings from "../components/PreferenceSettings";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import useErrorToast from "../state/useErrorToast";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function MessagingPreferences() {
  const [searchParams] = useSearchParams();
  const { enqueueErrorToast } = useErrorToast();
  const successView = useToggle(false);

  const getPreferences = React.useCallback(() => {
    return api
      .getPreferences({ authtoken: searchParams.get("authtoken") })
      .catch((e) => enqueueErrorToast(e));
  }, [searchParams, enqueueErrorToast]);
  const {
    state: subscriptions,
    loading,
    error,
  } = useAsyncFetch(getPreferences, { pickData: true });

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
    <PreferenceSettings
      subscriptions={subscriptions}
      onSubscriptionsSaved={() => successView.turnOn()}
    />
  );
}
