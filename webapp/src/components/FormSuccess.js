import i18next from "i18next";
import React from "react";

export default function FormSuccess({ message }) {
  if (!message) {
    return null;
  }
  const msg = i18next.t(message, { ns: "messages" });
  return <p className="d-block text-success small">{msg}</p>;
}
