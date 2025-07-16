import ContactListTags from "../components/ContactListTags";
import RLink from "../components/RLink";
import { t } from "../localization";
import useI18n from "../localization/useI18n";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";
import { useSearchParams } from "react-router-dom";

export default function ContactListSuccess() {
  const [params] = useSearchParams();
  const { changeLanguage } = useI18n();
  return (
    <Container className="text-center">
      {t("contact_list.success_intro")}
      <div className="button-stack">
        <Button
          href={
            params.get("eventName")
              ? `/contact-list?eventName=${params.get("eventName")}`
              : "/contact-list"
          }
          variant="outline-primary"
          as={RLink}
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
