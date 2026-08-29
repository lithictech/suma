import ContactListTags from "../components/ContactListTags";
import { t } from "../localization";
import useI18n from "../localization/useI18n";
import { withQuery } from "../routing/withQuery.ts";
import Button from "../ui/Button";
import Container from "../ui/Container";
import { useSearchParams } from "react-router-dom";

export default function ContactListSuccess() {
  const [params] = useSearchParams();
  const { changeLanguage } = useI18n();
  return (
    <Container className="text-center">
      {t("contact_list.success_intro")}
      <div className="button-stack">
        <Button
          to={withQuery("/contact-list", { eventName: params.get("eventName") })}
          variant="outline"
          className="w-75"
          onClick={() => changeLanguage("en")}
        >
          {t("contact_list.sign_up_again")}
        </Button>
        <ContactListTags />
      </div>
    </Container>
  );
}
