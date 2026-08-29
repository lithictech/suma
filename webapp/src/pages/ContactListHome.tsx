import sumaLogo from "../assets/images/suma-logo-word-512.png";
import ContactListTags from "../components/ContactListTags";
import { imageAltT, t } from "../localization";
import useI18n from "../localization/useI18n";
import { withQuery } from "../routing/withQuery.ts";
import useBackendGlobals from "../state/useBackendGlobals";
import Button from "../ui/Button";
import Container from "../ui/Container";
import { useSearchParams } from "react-router-dom";

export default function ContactListHome() {
  const [params] = useSearchParams();
  return (
    <Container className="text-center">
      <img
        src={sumaLogo}
        alt={imageAltT("suma_logo")}
        className="p-4"
        style={{ width: 250 }}
      />
      <h1 className="mb-4">{t("common.welcome_to_suma")}</h1>
      <div className="button-stack">
        <h5>{t("contact_list.choose_language")}</h5>
        <LanguageButtons eventName={params.get("eventName")} />
      </div>
      <ContactListTags />
    </Container>
  );
}

function LanguageButtons({ eventName }: { eventName: string | null }) {
  const { supportedLocales } = useBackendGlobals();
  const { changeLanguage } = useI18n();
  if (!supportedLocales.items) {
    return null;
  }
  return supportedLocales.items.map(({ code, native }) => (
    <Button
      key={code}
      className="btn-outline-secondary mt-2 w-75"
      to={withQuery(`/contact-list/add`, { eventName })}
      variant="outline"
      onClick={() => changeLanguage(code)}
    >
      {native}
    </Button>
  ));
}
