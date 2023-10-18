import { t } from "../localization";
import clsx from "clsx";
import isArray from "lodash/isArray";
import React from "react";

export default function FormSuccess({ message, center, className }) {
  if (!message) {
    return null;
  }
  let msgkey, vars;
  if (isArray(message)) {
    msgkey = message[0];
    vars = message[1];
  } else {
    msgkey = message;
    vars = {};
  }
  const msg = t(msgkey, { ...vars });
  return (
    <p className={clsx("d-block text-success small", center && "text-center", className)}>
      {msg}
    </p>
  );
}
