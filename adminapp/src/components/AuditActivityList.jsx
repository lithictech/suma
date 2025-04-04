import formatDate from "../modules/formatDate";
import AdminLink from "./AdminLink";
import RelatedList from "./RelatedList";
import React from "react";

export default function AuditActivityList({ activities }) {
  return (
    <RelatedList
      title="Audit Activities"
      headers={["At", "Summary", "Message", "Member"]}
      rows={activities}
      showMore
      keyRowAttr="id"
      toCells={(row) => [
        formatDate(row.createdAt),
        row.summary,
        <span key="msg">
          {row.messageName} / <code>{JSON.stringify(row.messageVars)}</code>
        </span>,
        <AdminLink model={row.member}>{row.member.name}</AdminLink>,
      ]}
    />
  );
}
