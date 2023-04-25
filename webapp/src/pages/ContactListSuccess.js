import ContactListTags from "../components/ContactListTags";
import RLink from "../components/RLink";
import { md, t } from "../localization";
import useI18Next from "../localization/useI18Next";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";
import { useSearchParams } from "react-router-dom";

export default function ContactListSuccess() {
  const [params] = useSearchParams();
  const { changeLanguage } = useI18Next();
  return (
    <Container className="text-center">
      {md("contact_list:success_intro")}
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
          {t("contact_list:sign_up_again")}
        </Button>
        <ContactListTags />
      </div>
    </Container>
  );
}
