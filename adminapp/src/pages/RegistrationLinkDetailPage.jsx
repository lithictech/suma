import api from "../api";
import AdminLink from "../components/AdminLink";
import Copyable from "../components/Copyable";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import formatDate from "../modules/formatDate";
import React from "react";

export default function RegistrationLinkDetailPage() {
  return (
    <ResourceDetail
      resource="organization_registration_link"
      apiGet={api.getOrganizationRegistrationLink}
      canEdit
      apiDelete={api.destroyOrganizationRegistrationLink}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: formatDate(model.createdAt) },
        { label: "Updated At", value: formatDate(model.updatedAt) },
        { label: "Created By", value: <AdminLink model={model.createdBy} /> },
        { label: "Organization", value: <AdminLink model={model.organization} /> },
        { label: "Intro EN", value: model.intro.en },
        { label: "Intro ES", value: model.intro.es },
        { label: "Event Start", value: formatDate(model.icalDtstart) },
        { label: "Event End", value: formatDate(model.icalDtend) },
        { label: "RRULE", value: model.icalRrule },
        { label: "Currently Open", value: model.currentlyWithinSchedule },
        {
          label: "Durable URL",
          value: <Copyable text={model.durableUrl} inline></Copyable>,
        },
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
          title="Upcoming Availabilities"
          rows={model.scheduledAvailabilities}
          headers={["Start", "End"]}
          keyRowAttr="startTime"
          toCells={(row) => [formatDate(row.startTime), formatDate(row.endTime)]}
        />,
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
