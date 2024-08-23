import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";

export default function VendorAccountDetailPage() {
  return (
    <ResourceDetail
      resource="vendor_account"
      apiGet={api.getVendorAccount}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Member",
          value: <AdminLink model={model.member}>{model.member.name}</AdminLink>,
        },
        {
          label: "Latest Access Code Magic Link",
          value: (
            <SafeExternalLink href={model.latestAccessCodeMagicLink}>
              {model.latestAccessCodeMagicLink}
            </SafeExternalLink>
          ),
        },
        { label: "Latest Access Code", value: model.latestAccessCode },
        {
          label: "Latest Access Code Requested At",
          value: model.latestAccessCodeRequestedAt
            ? dayjs(model.latestAccessCodeRequestedAt)
            : "",
        },
        {
          label: "Latest Access Code Set At",
          value: model.latestAccessCodeSetAt ? dayjs(model.latestAccessCodeSetAt) : "",
        },
      ]}
    >
      {(model) => (
        <>
          {model.configuration && (
            <DetailGrid
              title="Configuration"
              properties={[
                { label: "ID", value: <AdminLink model={model.configuration} /> },
                {
                  label: "Vendor",
                  value: (
                    <AdminLink model={model.configuration.vendor}>
                      {model.configuration.vendor?.name}
                    </AdminLink>
                  ),
                },
                {
                  label: "App Install Link",
                  value: (
                    <SafeExternalLink href={model.configuration.appInstallLink}>
                      {model.configuration.appInstallLink}
                    </SafeExternalLink>
                  ),
                },
                {
                  label: "Uses SMS?",
                  value: <BoolCheckmark>{model.configuration.usesSms}</BoolCheckmark>,
                },
                {
                  label: "Uses Email?",
                  value: <BoolCheckmark>{model.configuration.usesEmail}</BoolCheckmark>,
                },
                {
                  label: "Enabled?",
                  value: <BoolCheckmark>{model.configuration.enabled}</BoolCheckmark>,
                },
              ]}
            />
          )}
          {model.contact && (
            <DetailGrid
              title="Member Contact"
              properties={[
                { label: "ID", value: model.contact.id },
                {
                  label: "Member",
                  value: (
                    <AdminLink model={model.contact.member}>
                      {model.contact.member.name}
                    </AdminLink>
                  ),
                },
                { label: "Email", value: model.contact.email },
                { label: "Phone", value: model.contact.phone },
                { label: "Relay Key", value: model.contact.relayKey },
              ]}
            />
          )}
          <RelatedList
            title="Messages"
            rows={model.messages}
            headers={[
              "Id",
              "Created",
              "Content",
              "From",
              "To",
              "Handler Key",
              "Relay Key",
              "Timestamp",
            ]}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              dayjs(row.createdAt).format("lll"),
              row.messageContent,
              row.messageFrom,
              row.messageTo,
              row.messageHandlerKey,
              row.relayKey,
              dayjs(row.messageTimestamp).format("lll"),
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
