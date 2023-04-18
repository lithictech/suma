import sumaLogo from "../assets/images/suma-logo-word-512.png";
import ContactListTags from "../components/ContactListTags";
import { t } from "../localization";
import useI18Next from "../localization/useI18Next";
import { useBackendGlobals } from "../state/useBackendGlobals";
import clsx from "clsx";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";
import { useNavigate, useSearchParams } from "react-router-dom";

export default function ContactListHome() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const handleContactListNavigation = () => {
    navigate("/contact-list/add", { state: { eventName: params.get("eventName") } });
  };
  return (
    <Container>
      <div className="text-center">
        <img src={sumaLogo} alt="MySuma Logo" className="p-4" style={{ width: 250 }} />
        <h1 className="mb-4">{t("common:welcome_to_suma")}</h1>
        <div className="button-stack">
          <h5>Choose language</h5>
          <LanguageButtons />
        </div>
        <hr />
        <div className="button-stack">
          <Button
            onClick={handleContactListNavigation}
            variant="outline-primary"
            className="w-75"
          >
            Continue to savings
          </Button>
        </div>
        <ContactListTags />
      </div>
    </Container>
  );
}

function LanguageButtons() {
  const { supportedLocales } = useBackendGlobals();
  const { changeLanguage } = useI18Next();
  if (!supportedLocales.items) {
    return null;
  }
  return supportedLocales.items.map(({ code, native }) => (
    <Button
      key={code}
      variant="outline-secondary"
      className={clsx(
        "mt-2 w-75",
        i18next.language === code ? "btn-secondary text-white" : "btn-outline-secondary"
      )}
      onClick={() => changeLanguage(code)}
    >
      {native}
    </Button>
  ));
}
