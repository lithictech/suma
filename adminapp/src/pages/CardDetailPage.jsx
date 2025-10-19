import api from "../api";
import AdminLink from "../components/AdminLink";
import ExternalLinks from "../components/ExternalLinks";
import LegalEntity from "../components/LegalEntity";
import ResourceDetail, { ResourceSummary } from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function CardDetailPage() {
  return (
    <ResourceDetail
      resource="card"
      backTo={(m) => m.member.adminLink}
      apiGet={api.getCard}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Account Name", value: model.name },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Deleted At",
          value: model.softDeletedAt ? dayjs(model.softDeletedAt) : "",
        },
        { label: "Brand", value: model.brand },
        { label: "Last 4", value: model.last4 },
        { label: "Expires", value: `${model.expMonth}/${model.expYear}` },
        { label: "Stripe ID", value: model.stripeId },
        {
          label: "Member",
          value: <AdminLink model={model.member}>{model.member?.name}</AdminLink>,
        },
      ]}
    >
      {(model) => [
        <ResourceSummary>
          <LegalEntity legalEntity={model.legalEntity} />
        </ResourceSummary>,
        <ExternalLinks externalLinks={model.externalLinks} />,
      ]}
    </ResourceDetail>
  );
}
