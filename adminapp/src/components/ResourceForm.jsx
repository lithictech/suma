import api from "../api";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { isNil, mergeWith } from "lodash";
import assign from "lodash/assign";
import isArray from "lodash/isArray";
import { isObject } from "lodash/lang";
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

  const resource = mergeWith({}, baseResource, changes, (obj, src) => {
    // Since `_.merge()` only merges array indexes and does not replace arrays,
    // we need to check for empty arrays and return them, also return src when
    // it's an image or not an object (like a string).
    // This allows nested resources and sub-nested resources to be removed/set
    const isEmptyArray = isArray(src) && !isNil(src);
    if (!isObject(src) || isEmptyArray || src instanceof File) {
      return src;
    }
    // Otherwise, return default object and src merge
    return merge({}, obj, src);
  });
  return (
    <InnerForm
      isCreate={isCreate}
      resource={resource}
      setFields={setChanges}
      setField={setField}
      setFieldFromInput={setFieldFromInput}
      register={register}
      isBusy={isBusy}
      onSubmit={handleSubmit(submitter)}
    />
  );
}
