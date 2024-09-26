import sumaLogo from "../assets/images/suma-logo-word-512.png";
import ContactListTags from "../components/ContactListTags";
import RLink from "../components/RLink";
import { t } from "../localization";
import useI18n from "../localization/useI18n";
import useBackendGlobals from "../state/useBackendGlobals";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";
import { useSearchParams } from "react-router-dom";

export default function ContactListHome() {
  const [params] = useSearchParams();
  return (
    <Container className="text-center">
      <img
        src={sumaLogo}
        alt={t("common:suma_logo")}
        className="p-4"
        style={{ width: 250 }}
      />
      <h1 className="mb-4">{t("common.welcome_to_suma")}</h1>
      <div className="button-stack">
        <h5>{t("contact_list:choose_language")}</h5>
        <LanguageButtons eventName={params.get("eventName")} />
      </div>
      <ContactListTags />
    </Container>
  );
}

function LanguageButtons({ eventName }) {
  const { supportedLocales } = useBackendGlobals();
  const { changeLanguage } = useI18n();
  if (!supportedLocales.items) {
    return null;
  }
  return supportedLocales.items.map(({ code, native }) => (
    <Button
      key={code}
      as={RLink}
      className="btn-outline-secondary mt-2 w-75"
      href={eventName ? `/contact-list/add?eventName=${eventName}` : "/contact-list/add"}
      variant="outline-secondary"
      onClick={() => changeLanguage(code)}
    >
      {native}
    </Button>
  ));
}
