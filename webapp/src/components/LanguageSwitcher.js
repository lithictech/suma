import api from "../api";
import useI18Next from "../localization/useI18Next";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import i18next from "i18next";
import React from "react";
import { ButtonGroup } from "react-bootstrap";
import Button from "react-bootstrap/Button";

export default function LanguageSwitcher() {
  const { state: supportedLocales } = useAsyncFetch(api.getSupportedLocales, {
    default: i18next.language,
    pickData: true,
  });
  const { changeLanguage } = useI18Next();
  return (
    <ButtonGroup>
      {supportedLocales.items?.map(({ code, native }) => (
        <Button
          key={code}
          variant={i18next.language === code ? "primary" : "outline-primary"}
          onClick={() => changeLanguage(code)}
        >
          {native}
        </Button>
      ))}
    </ButtonGroup>
  );
}
