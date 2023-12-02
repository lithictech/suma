import FormLayout from "../components/FormLayout";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import ResourceForm from "./ResourceForm";
import React from "react";
import { useParams } from "react-router-dom";

export default function ResourceEdit({ apiGet, apiUpdate, Form }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { id: idStr } = useParams();
  const id = Number(idStr);
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
