import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs, dayjsOrNull } from "../modules/dayConfig";
import createRelativeUrl from "../shared/createRelativeUrl";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import SumaImage from "../shared/react/SumaImage";
import React from "react";

export default function ProgramDetailPage() {
  return (
    <ResourceDetail
      resource="program"
      apiGet={api.getProgram}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Image",
          value: (
            <SumaImage
              image={model.image}
              alt=""
              className="w-100"
              params={{ crop: "none" }}
              h={150}
            />
          ),
        },
        { label: "Name EN", value: model.name.en },
        { label: "Name ES", value: model.name.es },
        { label: "Description EN", value: model.description.en },
        { label: "Description ES", value: model.description.es },
        { label: "Opening Date", value: dayjs(model.periodBegin) },
        { label: "Closing Date", value: dayjs(model.periodEnd) },
        { label: "App Link", value: model.appLink },
        { label: "Ordinal", value: model.ordinal },
      ]}
    >
      {(model) => (
        <>
          <RelatedList
            title={`Commerce Offerings (${model.commerceOfferings?.length})`}
            rows={model.commerceOfferings}
            headers={["Id", "Description", "Opening Date", "Closing Date"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              <AdminLink model={row}>{row.description.en}</AdminLink>,
              dayjs(row.periodBegin).format("lll"),
              dayjs(row.periodEnd).format("lll"),
            ]}
          />
          <RelatedList
            title={`Vendor Services (${model.vendorServices?.length})`}
            rows={model.vendorServices}
            headers={["Id", "Name", "Vendor", "Opening Date", "Closing Date"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              <AdminLink key="name" model={row}>
                {row.name}
              </AdminLink>,
              <AdminLink key="vendor_name" model={row.vendor}>
                {row.vendor.name}
              </AdminLink>,
              dayjs(row.periodBegin).format("lll"),
              dayjs(row.periodEnd).format("lll"),
            ]}
          />
          <RelatedList
            title={`Payment Triggers (${model.paymentTriggers?.length})`}
            rows={model.paymentTriggers}
            headers={["Id", "Label", "Opening Date", "Closing Date"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              <AdminLink model={row}>{row.label}</AdminLink>,
              dayjs(row.activeDuringBegin).format("lll"),
              dayjs(row.activeDuringEnd).format("lll"),
            ]}
          />
          <RelatedList
            title={`Vendor Configurations (${model.configurations?.length})`}
            rows={model.configurations}
            keyRowAttr="id"
            headers={[
              "Id",
              "Created",
              "Vendor",
              "App Install Link",
              "Uses Email",
              "Uses SMS",
              "Enabled",
            ]}
            toCells={(row) => [
              <AdminLink model={row} />,
              dayjs(row.createdAt).format("lll"),
              <AdminLink key={row.vendor.name} model={row.vendor}>
                {row.vendor.name}
              </AdminLink>,
              <SafeExternalLink key={1} href={row.appInstallLink}>
                {row.appInstallLink}
              </SafeExternalLink>,
              row.usesEmail ? "Yes" : "No",
              row.usesSms ? "Yes" : "No",
              row.enabled ? "Yes" : "No",
            ]}
          />
          <RelatedList
            title="Program Enrollments"
            headers={["Id", "Member", "Organization", "Approved At", "Unenrolled At"]}
            rows={model.enrollments}
            addNewLabel="Enroll member or organization"
            addNewLink={createRelativeUrl(`/program-enrollment/new`, {
              programId: model.id,
              programLabel: `(${model.id}) ${model.name.en}`,
            })}
            addNewRole="program"
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              <AdminLink model={row.member}>{row.member?.name}</AdminLink>,
              <AdminLink model={row.organization}>{row.organization?.name}</AdminLink>,
              dayjsOrNull(row.approvedAt)?.format("lll"),
              dayjsOrNull(row.unenrolledAt)?.format("lll"),
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
