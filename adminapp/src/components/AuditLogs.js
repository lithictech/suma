import { dayjs } from "../modules/dayConfig";
import AdminLink from "./AdminLink";
import RelatedList from "./RelatedList";
import isEmpty from "lodash/isEmpty";
import React from "react";

export default function AuditLogs({ auditLogs }) {
  return (
    <RelatedList
      title="Audit Logs"
      headers={["At", "Event", "By", "Context"]}
      rows={auditLogs}
      keyRowAttr="id"
      toCells={(row) => [dayjs(row.at).format("lll"), event(row), by(row), context(row)]}
    />
  );
}

function event(log) {
  return `${log.event} (${log.fromState} -> ${log.toState})`;
}

function by(log) {
  if (!log.actor) {
    return "";
  }
  return (
    <AdminLink model={log.actor}>
      ({log.actor.id}) {log.actor.email || log.actor.name || "<no name>"}
    </AdminLink>
  );
}

function context(log) {
  if (!log.reason && isEmpty(log.messages)) {
    return "";
  } else if (log.reason && isEmpty(log.messages)) {
    return log.reason;
  } else if (!log.reason && !isEmpty(log.messages)) {
    return log.messages.join(", ");
  } else {
    return `${log.reason} / ${log.messages.join(", ")}`;
  }
}
