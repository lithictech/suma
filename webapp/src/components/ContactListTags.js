import { t } from "../localization";
import ExternalLink from "./ExternalLink";
import React from "react";
import Stack from "react-bootstrap/Stack";
import { Link } from "react-router-dom";

export default function ContactListTags() {
  return (
    <Stack direction="vertical" className="mt-4 text-center">
      <Link to="/privacy-policy">{t("common:privacy_policy")}</Link>
      <ExternalLink href="">Instagram</ExternalLink>
    </Stack>
  );
}
