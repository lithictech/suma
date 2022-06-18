import clsx from "clsx";
import i18next from "i18next";
import _ from "lodash";
import React from "react";

export default function FormSuccess({ message, center, ns, className }) {
  if (!message) {
    return null;
  }
  let msgkey, vars;
  if (_.isArray(message)) {
    msgkey = message[0];
    vars = message[1];
  } else {
    msgkey = message;
    vars = {};
  }
  msgkey = `${ns || "messages"}:${msgkey}`;
  const msg = i18next.t(msgkey, { ...vars });
  return (
    <p className={clsx("d-block text-success small", center && "text-center", className)}>
      {msg}
    </p>
  );
}
