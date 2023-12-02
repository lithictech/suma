import FormLayout from "../components/FormLayout";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import ResourceForm from "./ResourceForm";
import React from "react";

export default function ResourceEdit({ id, apiGet, apiUpdate, Form }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const apiGetWithErr = React.useCallback(() => {
    return apiGet({ id }).catch(enqueueErrorSnackbar);
  }, [apiGet, enqueueErrorSnackbar, id]);
  const { state, loading, error } = useAsyncFetch(apiGetWithErr, {
    default: {},
    pickData: true,
  });
  const handleApplyChange = React.useCallback(
    (changes) => {
      return apiUpdate({ id, ...changes });
    },
    [apiUpdate, id]
  );

  // TODO: Add an error page at some point
  if (loading || error) {
    return <FormLayout isBusy />;
  }

  return (
    <ResourceForm
      InnerForm={Form}
      baseResource={state}
      isCreate={false}
      applyChange={handleApplyChange}
    />
  );
}
