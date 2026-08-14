import { t } from "../localization";
import ExternalLink from "./ExternalLink";
import React from "react";
import Stack from "react-bootstrap/Stack";

export default function ContactListTags() {
  return (
    <Stack direction="vertical" className="mt-4 text-center">
      <ExternalLink href="/privacy-policy">{t("common.privacy_policy")}</ExternalLink>
      <ExternalLink href="https://www.instagram.com/mysuma/">Instagram</ExternalLink>
    </Stack>
  );
}
