import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import formatDate from "../modules/formatDate";
import React from "react";

export default function RegistrationLinkDetailPage() {
  return (
    <ResourceDetail
      resource="organization_registration_link"
      apiGet={api.getOrganizationRegistrationLink}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: formatDate(model.createdAt) },
        { label: "Updated At", value: formatDate(model.updatedAt) },
        { label: "Created By", value: <AdminLink model={model.createdBy} /> },
        { label: "Organization", value: <AdminLink model={model.organization} /> },
        { label: "ICal Event", value: model.icalEvent },
        { label: "Currently Open", value: model.currentlyWithinSchedule },
        { label: "Durable URL", value: model.durableUrl },
        {
          label: "QR Code",
          value: (
            <img
              alt="qr code for url"
              src={model.durableUrlQrCode}
              height={120}
              width={120}
            ></img>
          ),
        },
      ]}
    >
      {(model) => [
        <RelatedList
          title="Memberships"
          rows={model.memberships}
          headers={["Id", "Member"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="mem" model={row.member} />,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
