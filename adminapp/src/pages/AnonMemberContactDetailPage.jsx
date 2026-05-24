import api from "../api";
import AdminLink from "../components/AdminLink";
import Copyable from "../components/Copyable";
import ExternalLinks from "../components/ExternalLinks";
import RelatedList from "../components/RelatedList";
import RelatedListRemote from "../components/RelatedListRemote";
import ResourceDetail from "../components/ResourceDetail";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import React from "react";

export default function AnonMemberContactDetailPage() {
  return (
    <ResourceDetail
      resource="member_contact"
      apiGet={api.getAnonMemberContact}
      apiDelete={api.destroyMemberContact}
      canEdit
      properties={(model) => [
        ...resourceDetailCommonFields(model),
        {
          label: "Member",
          value: <AdminLink model={model.member}>{model.member.name}</AdminLink>,
        },
        {
          label: "Address",
          value: <Copyable text={model.formattedAddress} inline></Copyable>,
        },
        { label: "Relay", value: model.relayKey },
        { label: "External Relay Id", value: model.externalRelayId },
      ]}
    >
      {(model) => [
        <ExternalLinks externalLinks={model.externalLinks} />,
        <RelatedListRemote
          title="Extenal Accounts"
          collection={model.vendorAccounts}
          headers={["Id", "Vendor"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row} />,
            <AdminLink model={row.configuration.vendor?.name}>
              {row.configuration.vendor?.name}
            </AdminLink>,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
