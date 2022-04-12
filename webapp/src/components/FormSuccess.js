import React from "react";
import { useTranslation } from "react-i18next";

export default function FormSuccess({ message }) {
  const { t } = useTranslation("messages");
  if (!message) {
    return null;
  }
  const msg = t(message);
  return <p className="d-block text-success small">{msg}</p>;
}
