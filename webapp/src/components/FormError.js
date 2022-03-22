import React from "react";
import {useTranslation} from "react-i18next";


export default function FormError({error}) {
  const { t } = useTranslation('errors');
  if (!error) {
    return null;
  }
  const msg = t(error);
  return <p className="d-block text-danger small">{msg}</p>
}
