import sumaLogo from "../assets/images/suma-logo-word-512.png";
import ExternalLink from "../components/ExternalLink";
import RLink from "../components/RLink";
import TranslationToggle from "../components/TranslationToggle";
import { t } from "../localization";
import externalLinks from "../modules/externalLinks";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";

export default function Home() {
  return (
    <Container className="text-center">
      <img src={sumaLogo} alt="MySuma Logo" className="p-4" style={{ width: 250 }} />
      <h1 className="mb-4">{t("common:welcome_to_suma")}</h1>
      <div className="button-stack">
        <Button href="/start" variant="outline-primary" as={RLink} className="w-75">
          {t("forms:continue")}
        </Button>
        <ExternalLink
          component={Button}
          href={externalLinks.sumaIntroLink}
          variant="outline-secondary"
          className="w-75 mt-3 nowrap"
        >
          {t("common:learn_more")}
        </ExternalLink>
        <TranslationToggle classes="mt-3 mx-auto w-75" />
      </div>
    </Container>
  );
}
