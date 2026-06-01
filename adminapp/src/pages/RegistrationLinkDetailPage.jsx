import api from "../api";
import AdminLink from "../components/AdminLink";
import Copyable from "../components/Copyable";
import RelatedList from "../components/RelatedList";
import RelatedListRemote from "../components/RelatedListRemote";
import ResourceDetail from "../components/ResourceDetail";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
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
        ...resourceDetailCommonFields(model),
        { label: "Organization", value: <AdminLink model={model.organization} label /> },
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
        <RelatedListRemote
          title="Memberships"
          collection={model.memberships}
          headers={["Id", "Member"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} label />,
            <AdminLink key="mem" model={row.member} label />,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
