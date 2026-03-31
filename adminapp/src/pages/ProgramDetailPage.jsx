import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditActivityList from "../components/AuditActivityList";
import EligibilityRequirementsRelatedList from "../components/EligibilityRequirementsRelatedList";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import detailPageImageProperties from "../components/detailPageImageProperties";
import { dayjs } from "../modules/dayConfig";
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
        ...detailPageImageProperties(model.image),
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
          title="Commerce Offerings"
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
          title="Pricings"
          addNewLabel="Add Program Pricing"
          addNewLink={createRelativeUrl(`/program-pricing/new`, {
            programId: model.id,
            programLabel: `(${model.id}) ${model.name.en || "-"}`,
          })}
          addNewRole="programPricing"
          rows={model.pricings}
          headers={["Id", "Service", "Rate"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="service" model={row.vendorService}>
              {row.vendorService.internalName}
            </AdminLink>,
            <AdminLink key="rate" model={row.vendorServiceRate}>
              {row.vendorServiceRate.internalName}
            </AdminLink>,
          ]}
        />,
        <RelatedList
          title="Payment Triggers"
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
          title="Vendor Configurations"
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
        <EligibilityRequirementsRelatedList model={model} type="program" />,
        <AuditActivityList activities={model.auditActivities} />,
      ]}
    </ResourceDetail>
  );
}
