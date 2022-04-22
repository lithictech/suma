import clsx from "clsx";
import React from "react";
import { useTranslation } from "react-i18next";

export default function FormError({ error, noMargin }) {
  const { t } = useTranslation("errors");
  if (!error) {
    return null;
  }
  const msg = t(error);
  const cls = clsx("d-block text-danger small", noMargin && "m-0");
  return <p className={cls}>{msg}</p>;
}
