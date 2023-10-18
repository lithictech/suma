import SafeExternalLink from "../shared/react/SafeExternalLink";
import RelatedList from "./RelatedList";
import React from "react";

export default function ExternalLinks({ externalLinks }) {
  return (
    <RelatedList
      title="External Links"
      headers={["Name", "Url"]}
      rows={externalLinks}
      keyRowAttr="url"
      toCells={(row) => [
        row.name,
        <SafeExternalLink key={1} href={row.url}>
          {row.url}
        </SafeExternalLink>,
      ]}
    />
  );
}
