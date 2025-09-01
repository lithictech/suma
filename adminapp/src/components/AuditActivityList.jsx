import formatDate from "../modules/formatDate";
import AdminLink from "./AdminLink";
import AdminMarkdown from "./AdminMarkdown";
import RelatedList from "./RelatedList";
import { makeStyles } from "@mui/styles";
import React from "react";

export default function AuditActivityList({ activities }) {
  return (
    <RelatedList
      title="Audit Activities"
      headers={["At", "Summary", "Message", "Member"]}
      rows={activities}
      keyRowAttr="id"
      toCells={(row) => [
        formatDate(row.createdAt),
        <ActivityHtml md={row.summaryMd} />,
        <span key="msg">
          {row.messageName}
          {Object.keys(row.messageVars).length > 0 ? (
            <span>
              {" "}
              / <code>{JSON.stringify(row.messageVars)}</code>
            </span>
          ) : (
            ""
          )}
        </span>,
        <AdminLink model={row.member}>{row.member.name}</AdminLink>,
      ]}
    />
  );
}

function ActivityHtml({ md }) {
  const classes = useStyles();
  const reclassed = md
    .replaceAll('class="code"', `class="${classes.code}"`)
    .replaceAll(`class="quote"`, `class="${classes.quote}"`)
    .replaceAll(`class="email"`, `class="${classes.email}"`)
    .replaceAll(`class="action"`, `class="${classes.action}"`);

  return <AdminMarkdown>{reclassed}</AdminMarkdown>;
}

const useStyles = makeStyles((theme) => ({
  code: { fontSize: "95%" },
  quote: { color: theme.palette.success.main },
  email: { fontWeight: "bold" },
  action: { fontWeight: "bold" },
}));
