import { t } from "../localization";
import useI18Next from "../localization/useI18Next";
import React from "react";
import Button from "react-bootstrap/Button";

export default function TranslationToggle({ classes }) {
  const { language } = useI18Next();
  return (
    <div className={classes}>
      {language !== "en" ? (
        <Translate
          to="en"
          label={t("common:in_english")}
          title={t("common:translate_to_english")}
        />
      ) : (
        <Translate
          to="es"
          label={t("common:in_spanish")}
          title={t("common:translate_to_spanish")}
        />
      )}
    </div>
  );
}

const Translate = ({ to, label, title }) => {
  const { changeLanguage } = useI18Next();
  return (
    <Button variant="link" onClick={() => changeLanguage(to)} title={title}>
      <i className="bi bi-translate"></i> <i>{label}</i>
    </Button>
  );
};
