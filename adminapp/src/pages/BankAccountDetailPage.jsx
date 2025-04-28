import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import ResourceDetail, { ResourceSummary } from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import isEmpty from "lodash/isEmpty";
import React from "react";

export default function BankAccountDetailPage() {
  return (
    <ResourceDetail
      resource="bank_account"
      apiGet={api.getBankAccount}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Account Name", value: model.name },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Deleted At",
          value: model.softDeletedAt ? dayjs(model.softDeletedAt) : "",
        },
        {
          label: "Verified At",
          value: model.verifiedAt
            ? dayjs(model.verifiedAt).format("lll")
            : "(not verified)",
        },
        { label: "Routing Number", value: model.routingNumber },
        { label: "Account Number", value: model.accountNumber },
        { label: "Account Type", value: model.accountType },
        model.member && {
          label: "Member",
          value: (
            <AdminLink model={model.member}>
              ({model.member.id}) {model.member.name}
            </AdminLink>
          ),
        },
      ]}
    >
      {(model) => [
        <ResourceSummary>
          <LegalEntity
            address={model.legalEntity.address}
            name={model.legalEntity.name}
          />
        </ResourceSummary>,
      ]}
    </ResourceDetail>
  );
}

function LegalEntity({ name, address }) {
  if (isEmpty(address)) {
    return null;
  }
  const { address1, address2, city, stateOrProvince, postalCode, country } =
    address || {};
  return (
    <div>
      <DetailGrid
        title="Legal Entity"
        properties={[
          { label: "Name", value: name },
          {
            label: "Street Address",
            value: [address1, address2].filter(Boolean).join(" "),
          },
          { label: "City", value: city },
          { label: "State", value: stateOrProvince },
          { label: "Postal Code", value: postalCode },
          { label: "Country", value: country },
        ]}
      />
    </div>
  );
}
