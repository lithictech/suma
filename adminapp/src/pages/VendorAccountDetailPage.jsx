import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import ExternalLinks from "../components/ExternalLinks";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import Unavailable from "../components/Unavailable";
import { dayjs } from "../modules/dayConfig";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";

export default function VendorAccountDetailPage() {
  return (
    <ResourceDetail
      apiGet={api.getVendorAccount}
      title={(model) => `Vendor Account ${model.id}`}
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
          value: model.latestAccessCodeRequestedAt
            ? dayjs(model.latestAccessCodeSetAt)
            : "",
        },
      ]}
    >
      {(model) => (
        <>
          {model.configuration && (
            <DetailGrid
              title="Configuration"
              properties={[
                { label: "ID", value: model.configuration.id },
                {
                  label: "Vendor",
                  value: (
                    <AdminLink model={model.configuration.vendor}>
                      {model.configuration.vendor?.name}
                    </AdminLink>
                  ),
                },
                { label: "Auth HTTP Method", value: model.configuration.authHttpMethod },
                {
                  label: "Auth URL",
                  value: (
                    <SafeExternalLink href={model.configuration.authUrl}>
                      {model.configuration.authUrl}
                    </SafeExternalLink>
                  ),
                },
                {
                  label: "Auth Body Template",
                  value: model.configuration.authBodyTemplate,
                },
                { label: "Auth Header", value: model.configuration.authHeaders },
                {
                  label: "App Install Link",
                  value: (
                    <SafeExternalLink href={model.configuration.appInstallLink}>
                      {model.configuration.appInstallLink}
                    </SafeExternalLink>
                  ),
                },
                { label: "Enabled?", value: model.configuration.enabled },
                { label: "Uses Email?", value: model.configuration.usesEmail },
                { label: "Uses SMS?", value: model.configuration.usesSms },
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
                {
                  label: "External Links",
                  value: <ExternalLinks externalLinks={model.contact.externalLinks} />,
                },
              ]}
            />
          )}
        </>
      )}
    </ResourceDetail>
  );
}
