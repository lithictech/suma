import sumaLogo from "../assets/images/suma-logo-word-512.png";
import AddToHomescreen from "../components/AddToHomescreen";
import ExternalLink from "../components/ExternalLink";
import RLink from "../components/RLink";
import TranslationToggle from "../components/TranslationToggle";
import { imageAltT, t } from "../localization";
import externalLinks from "../modules/externalLinks";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";

export default function Home() {
  return (
    <Container>
      <div className="text-center">
        <img
          src={sumaLogo}
          alt={imageAltT("suma_logo")}
          className="p-4"
          style={{ width: 250 }}
        />
        <h1 className="mb-4">{t("common.welcome_to_suma")}</h1>
        <div className="button-stack">
          <Button href="/start" variant="outline-primary" as={RLink} className="w-75">
            {t("forms.continue")}
          </Button>
          <ExternalLink
            component={Button}
            href={externalLinks.sumaIntroLink}
            variant="outline-secondary"
            className="w-75 mt-3 text-nowrap"
          >
            {t("common.learn_more")}
          </ExternalLink>
          <TranslationToggle classes="my-3 mx-auto w-75" />
        </div>
      </div>
      <AddToHomescreen />
    </Container>
  );
}
