import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function VendorServiceRateDetailPage() {
  return (
    <ResourceDetail
      resource="vendor_service_rate"
      apiGet={api.getVendorServiceRate}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Internal Name", value: model.internalName },
        { label: "External Name", value: model.externalName },
        { label: "Surcharge", value: <Money>{model.surcharge}</Money> },
        { label: "Unit Amount", value: <Money>{model.unitAmount}</Money> },
        { label: "Unit Offset", value: model.unitOffset },
        { label: "Ordinal", value: model.ordinal },
        {
          label: "Undiscounted Rate",
          value: (
            <AdminLink model={model.undiscountedRate}>
              {model.undiscountedRate?.internalName}
            </AdminLink>
          ),
        },
      ]}
    >
      {(model) => [
        <RelatedList
          title="Program Pricings"
          rows={model.programPricings}
          headers={["Id", "Program", "Service"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row}>{row.id}</AdminLink>,
            <AdminLink model={row.program}>{row.program.name.en}</AdminLink>,
            <AdminLink model={row.vendorService}>
              {row.vendorService.internalName}
            </AdminLink>,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
