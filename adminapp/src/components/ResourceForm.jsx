import api from "../api";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import HelmetTitle from "./HelmetTitle";
import assign from "lodash/assign";
import isArray from "lodash/isArray";
import isNil from "lodash/isNil";
import isObject from "lodash/isObject";
import merge from "lodash/merge";
import mergeWith from "lodash/mergeWith";
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
      } else if (e.target.type === "number") {
        setField(e.target.name, Number(e.target.value));
      } else {
        setField(e.target.name, e.target.value);
      }
    },
    [setField]
  );

  const clearField = React.useCallback(
    (f) => {
      const newChanges = assign({}, changes);
      delete newChanges[f];
      setChanges(newChanges);
    },
    [changes]
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
    <>
      <HelmetTitle
        title={isCreate ? "Create" : `Edit | ${resource.label} | ${resource.id}`}
      />
      <InnerForm
        isCreate={isCreate}
        resource={resource}
        setFields={setChanges}
        setField={setField}
        setFieldFromInput={setFieldFromInput}
        clearField={clearField}
        register={register}
        isBusy={isBusy}
        onSubmit={handleSubmit(submitter)}
      />
    </>
  );
}
