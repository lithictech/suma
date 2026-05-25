import FormLayout from "../components/FormLayout";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { simplifyCollections } from "../modules/apicollection";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import ResourceForm from "./ResourceForm";
import isEmpty from "lodash/isEmpty";
import { useSnackbar } from "notistack";
import React from "react";
import { useParams } from "react-router-dom";

/**
 * @param apiGet API method to get the resource.
 * @param expand Array of fields to expand in the API response.
 * @param apiUpdate API method to update the resource.
 * @param alwaysApply If false, show 'no changes to save' if there are no changes queued.
 *   If true, always update on submit. Only useful where submitting no parameters
 *   has some other side effect.
 * @param Form Form component to use.
 */
export default function ResourceEdit({ apiGet, expand, apiUpdate, alwaysApply, Form }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { enqueueSnackbar } = useSnackbar();
  const { id: idStr } = useParams();
  const id = Number(idStr);
  const apiGetWithErr = React.useCallback(() => {
    return apiGet({ id, expand }).catch(enqueueErrorSnackbar);
  }, [apiGet, expand, enqueueErrorSnackbar, id]);
  const { state, loading, error } = useAsyncFetch(apiGetWithErr, {
    default: {},
    pickData: true,
  });
  const handleApplyChange = React.useCallback(
    (changes) => {
      if (!alwaysApply && isEmpty(changes)) {
        enqueueSnackbar("No changes to save.");
        window.history.back();
        return Promise.resolve();
      }
      return apiUpdate(simplifyCollections({ id, expand, ...changes }));
    },
    [apiUpdate, expand, enqueueSnackbar, id, alwaysApply]
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
