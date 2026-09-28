import { t } from "../localization";
import ExternalLink from "./ExternalLink";
import RLink from "./RLink";
import React from "react";
import Stack from "react-bootstrap/Stack";

export default function ContactListTags() {
  return (
    <Stack direction="vertical" className="mt-4 text-center">
      <RLink href="/privacy-policy" className="a11y-target">
        {t("common.privacy_policy")}
      </RLink>
      <ExternalLink href="https://www.instagram.com/mysuma/" className="a11y-target">
        Instagram
      </ExternalLink>
    </Stack>
  );
}
