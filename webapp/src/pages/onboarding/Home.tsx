import sumaLogo from "../../assets/images/suma-logo-word-512.png";
import AddToHomescreen from "../../components/AddToHomescreen";
import TranslationToggle from "../../components/TranslationToggle";
import { dt, imageAltT, t } from "../../localization";
import externalLinks from "../../modules/externalLinks";
import ExternalLink from "../../routing/ExternalLink.tsx";
import useUser from "../../state/useUser";
import Button from "../../ui/Button";
import Page from "../../ui/Page.tsx";
import Stack from "../../ui/Stack.tsx";

export default function Home() {
  const { registrationSession } = useUser();

  return (
    <Page>
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
          <Button to="/start" variant="primary" size="lg" className="w-100">
            {t("forms.continue")}
          </Button>
          <ExternalLink href={externalLinks.sumaIntroLink} className="text-nowrap">
            {t("common.learn_more")}
          </ExternalLink>
          <TranslationToggle className="my-3" />
        </Stack>
      </Stack>
      <AddToHomescreen />
    </Page>
  );
}
