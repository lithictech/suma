import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import SumaImage from "../components/SumaImage";
import { dayjs, dayjsOrNull } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import createRelativeUrl from "../shared/createRelativeUrl";
import SafeExternalLink from "../shared/react/SafeExternalLink";
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
        { label: "App Link Text EN", value: model.appLinkText.en },
        { label: "App Link Text ES", value: model.appLinkText.es },
        { label: "Ordinal", value: model.ordinal },
        { label: "Lyft Pass Program", value: model.lyftPassProgramId },
      ]}
    >
      {(model) => [
        <RelatedList
          title={`Commerce Offerings (${model.commerceOfferings?.length})`}
          rows={model.commerceOfferings}
          headers={["Id", "Description", "Opening Date", "Closing Date"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink model={row}>{row.description.en}</AdminLink>,
            formatDate(row.periodBegin),
            formatDate(row.periodEnd),
          ]}
        />,
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
            formatDate(row.periodBegin),
            formatDate(row.periodEnd),
          ]}
        />,
        <RelatedList
          title={`Payment Triggers (${model.paymentTriggers?.length})`}
          rows={model.paymentTriggers}
          headers={["Id", "Label", "Opening Date", "Closing Date"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink model={row}>{row.label}</AdminLink>,
            formatDate(row.activeDuringBegin),
            formatDate(row.activeDuringEnd),
          ]}
        />,
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
            formatDate(row.createdAt),
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
        />,
        <RelatedList
          title="Program Enrollments"
          headers={["Id", "Enrollee", "Enrollee Type", "Approved At", "Unenrolled At"]}
          rows={model.enrollments}
          addNewLabel="Enroll member, organization or role"
          addNewLink={createRelativeUrl(`/program-enrollment/new`, {
            programId: model.id,
            programLabel: `(${model.id}) ${model.name.en}`,
          })}
          addNewRole="program"
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink model={row.enrollee}>{row.enrollee?.name}</AdminLink>,
            row.enrolleeType,
            dayjsOrNull(row.approvedAt)?.format("lll"),
            dayjsOrNull(row.unenrolledAt)?.format("lll"),
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
