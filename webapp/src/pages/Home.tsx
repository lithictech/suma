import sumaLogo from "../assets/images/suma-logo-word-512.png";
import AddToHomescreen from "../components/AddToHomescreen";
import ExternalLink from "../components/ExternalLink";
import TranslationToggle from "../components/TranslationToggle";
import { dt, imageAltT, t } from "../localization";
import externalLinks from "../modules/externalLinks";
import useUser from "../state/useUser";
import Button from "../ui/Button";
import Container from "../ui/Container";
import Stack from "../ui/Stack.tsx";
import React from "react";

export default function Home() {
  const { registrationSession } = useUser();

  return (
    <Container>
      <Stack direction="vertical" center>
        <img
          src={sumaLogo}
          alt={imageAltT("suma_logo")}
          className="p-4"
          style={{ width: 250 }}
        />
        <h1 className="mb-4">{t("common.welcome_to_suma")}</h1>
        {registrationSession && (
          <div className="mb-4">{dt(registrationSession.intro)}</div>
        )}
        <Stack gap={2} direction="vertical" center>
          <Button href="/start" variant="outline" className="w-75">
            {t("forms.continue")}
          </Button>
          <ExternalLink
            component={Button}
            href={externalLinks.sumaIntroLink}
            variant="text"
            className="w-75 mt-3 text-nowrap"
          >
            {t("common.learn_more")}
          </ExternalLink>
          <TranslationToggle className="my-3" />
        </Stack>
      </Stack>
      <AddToHomescreen />
    </Container>
  );
}
