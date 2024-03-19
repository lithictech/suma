import api from "../api";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import assign from "lodash/assign";
import merge from "lodash/merge";
import set from "lodash/set";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function ResourceForm({ InnerForm, baseResource, isCreate, applyChange }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const navigate = useNavigate();
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();
  const [changes, setChanges] = React.useState({});

  const submitter = React.useCallback(() => {
    busy();
    const p = applyChange(changes);
    if (!p) {
      console.error("applyChange must return a promise");
      return;
    }
    p.then(api.followRedirect(navigate)).tapCatch(notBusy).catch(enqueueErrorSnackbar);
  }, [applyChange, busy, changes, enqueueErrorSnackbar, navigate, notBusy]);

  const setField = React.useCallback(
    (f, v) => {
      const newChanges = assign({}, changes);
      set(newChanges, f, v);
      setChanges(newChanges);
    },
    [changes]
  );

  const setFieldFromInput = React.useCallback(
    (e) => {
      if (e.target.type === "checkbox") {
        setField(e.target.name, e.target.checked);
      } else {
        setField(e.target.name, e.target.value);
      }
    },
    [setField]
  );

  return (
    <InnerForm
      isCreate={isCreate}
      resource={merge({}, baseResource, changes)}
      setFields={setChanges}
      setField={setField}
      setFieldFromInput={setFieldFromInput}
      register={register}
      isBusy={isBusy}
      onSubmit={handleSubmit(submitter)}
    />
  );
}
