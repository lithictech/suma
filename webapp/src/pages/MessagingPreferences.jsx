import api from "../api";
import PreferenceSettings from "../components/PreferenceSettings";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useErrorToast from "../state/useErrorToast";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function MessagingPreferences() {
  const [searchParams] = useSearchParams();
  const { enqueueErrorToast } = useErrorToast();

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
  return <PreferenceSettings subscriptions={subscriptions} />;
}
