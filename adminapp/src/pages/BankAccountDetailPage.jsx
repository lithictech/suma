import api from "../api";
import AdminLink from "../components/AdminLink";
import LegalEntity from "../components/LegalEntity";
import ResourceDetail, { ResourceSummary } from "../components/ResourceDetail";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function BankAccountDetailPage() {
  return (
    <ResourceDetail
      resource="bank_account"
      apiGet={api.getBankAccount}
      backTo={(m) => m.member.adminLink}
      properties={(model) => [
        ...resourceDetailCommonFields(model),
        { label: "Account Name", value: model.name },
        {
          label: "Verified At",
          value: model.verifiedAt ? dayjs(model.verifiedAt) : "(not verified)",
        },
        { label: "Routing Number", value: model.routingNumber },
        { label: "Account Number", value: model.maskedAccountNumber },
        { label: "Account Type", value: model.accountType },
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
      ]}
    </ResourceDetail>
  );
}
