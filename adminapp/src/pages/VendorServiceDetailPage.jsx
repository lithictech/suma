import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditActivityList from "../components/AuditActivityList";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import detailPageImageProperties from "../components/detailPageImageProperties";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function VendorServiceDetailPage() {
  return (
    <ResourceDetail
      resource="vendor_service"
      apiGet={api.getVendorService}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        ...detailPageImageProperties(model.image),
        { label: "External Name", value: model.externalName },
        { label: "Internal Name", value: model.internalName },
        {
          label: "Vendor",
          value: <AdminLink model={model.vendor}>{model.vendor?.name}</AdminLink>,
        },
        { label: "Opening Date", value: dayjs(model.periodBegin) },
        { label: "Closing Date", value: dayjs(model.periodEnd) },
        { label: "Mobility Adapter", value: model.mobilityAdapterSettingName },
        {
          label: "Constraints",
          value: <code>{JSON.stringify(model.constraints)}</code>,
        },
      ]}
    >
      {(model) => [
        <RelatedList
          title="Program Pricings"
          rows={model.programPricings}
          headers={["Id", "Program", "Rate"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row}>{row.id}</AdminLink>,
            <AdminLink model={row.program}>{row.program.name.en}</AdminLink>,
            <AdminLink model={row.vendorServiceRate}>
              {row.vendorServiceRate.name}
            </AdminLink>,
          ]}
        />,
        <RelatedList
          title="Categories"
          rows={model.categories}
          headers={["Id", "Name", "Slug"]}
          keyRowAttr="id"
          toCells={(row) => [row.id, row.name, row.slug]}
        />,
        <AuditActivityList activities={model.auditActivities} />,
      ]}
    </ResourceDetail>
  );
}
