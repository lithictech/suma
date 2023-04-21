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
import { useSearchParams } from "react-router-dom";

export default function ContactListHome() {
  const [params] = useSearchParams();
  return (
    <Container className="text-center">
      <img src={sumaLogo} alt="MySuma Logo" className="p-4" style={{ width: 250 }} />
      <h1 className="mb-4">{t("common:welcome_to_suma")}</h1>
      <div className="button-stack">
        <h5>To continue to your savings, choose your preferred language</h5>
        <LanguageButtons eventName={params.get("eventName")} />
      </div>
      <ContactListTags />
    </Container>
  );
}

function LanguageButtons({ eventName }) {
  const { supportedLocales } = useBackendGlobals();
  const { changeLanguage } = useI18Next();
  if (!supportedLocales.items) {
    return null;
  }
  return supportedLocales.items.map(({ code, native }) => (
    <Button
      href={eventName ? `/contact-list/add?eventName=${eventName}` : "/contact-list/add"}
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
