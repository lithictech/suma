import sumaLogo from "../../assets/images/suma-logo-word-512.png";
import AddToHomescreen from "../../components/AddToHomescreen";
import ExternalLink from "../../components/ExternalLink";
import TranslationToggle from "../../components/TranslationToggle";
import { dt, imageAltT, t } from "../../localization";
import externalLinks from "../../modules/externalLinks";
import useUser from "../../state/useUser";
import Button from "../../ui/Button";
import Container from "../../ui/Container";
import Stack from "../../ui/Stack.tsx";
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
        <Stack gap={4} direction="vertical" center>
          <h1 className="mb-2">{t("common.welcome_to_suma")}</h1>
          {registrationSession && (
            <div className="mb-4">{dt(registrationSession.intro)}</div>
          )}
          <Button href="/start" variant="primary" size="lg" className="w-100">
            {t("forms.continue")}
          </Button>
          <ExternalLink
            component={Button}
            href={externalLinks.sumaIntroLink}
            variant="text"
            className="text-nowrap"
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
