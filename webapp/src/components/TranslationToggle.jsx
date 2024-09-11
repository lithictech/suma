import { t } from "../localization";
import useI18n from "../localization/useI18n";
import React from "react";
import Button from "react-bootstrap/Button";

export default function TranslationToggle({ classes }) {
  const { currentLanguage } = useI18n();
  return (
    <div className={classes}>
      {currentLanguage !== "en" ? (
        <Translate
          to="en"
          label={t("common.in_english")}
          title={t("common.translate_to_english")}
        />
      ) : (
        <Translate
          to="es"
          label={t("common.in_spanish")}
          title={t("common.translate_to_spanish")}
        />
      )}
    </div>
  );
}

const Translate = ({ to, label, title }) => {
  const { changeLanguage } = useI18n();
  return (
    <Button variant="link" onClick={() => changeLanguage(to)} title={title}>
      <i className="bi bi-translate"></i> <i>{label}</i>
    </Button>
  );
};
