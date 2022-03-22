import React from "react";
import {useTranslation} from "react-i18next";


export default function FormError({code}) {
  const { t } = useTranslation('error');
  if (!code) {
    return null;
  }
  const error = t(code);
  return <p className="d-block text-danger small">{error}</p>
}
