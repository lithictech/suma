import React from "react";
import { useTranslation } from "react-i18next";

export default function FormError({ error }, noMargin = false) {
  const { t } = useTranslation("errors");
  if (!error) {
    return null;
  }
  const msg = t(error);
  return <p className={`d-block text-danger small ${noMargin ? "m-0" : null}`}>{msg}</p>;
}
