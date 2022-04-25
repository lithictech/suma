import clsx from "clsx";
import i18next from "i18next";
import React from "react";

export default function FormError({ error, noMargin }) {
  if (!error) {
    return null;
  }
  const msg = i18next.t(error, { ns: "errors" });
  const cls = clsx("d-block text-danger small", noMargin && "m-0");
  return <p className={cls}>{msg}</p>;
}
