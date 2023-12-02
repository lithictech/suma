import api from "../api";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import merge from "lodash/merge";
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

  return (
    <InnerForm
      isCreate={isCreate}
      resource={merge({}, baseResource, changes)}
      setFields={setChanges}
      setField={(f, v) => setChanges({ ...changes, [f]: v })}
      setFieldFromInput={(e) =>
        setChanges({ ...changes, [e.target.name]: e.target.value })
      }
      register={register}
      isBusy={isBusy}
      onSubmit={handleSubmit(submitter)}
    />
  );
}
