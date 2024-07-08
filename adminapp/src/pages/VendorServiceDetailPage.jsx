import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function VendorServiceDetailPage() {
  return (
    <ResourceDetail
      apiGet={api.getVendorService}
      title={(model) => `Vendor Service ${model.id}`}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Name", value: model.name },
        { label: "Internal Name", value: model.internalName },
        { label: "Mobility Vendor Adapter Key", value: model.mobilityVendorAdapterKey },
        {
          label: "Vendor",
          value: <AdminLink model={model.vendor}>{model.vendor?.name}</AdminLink>,
        },
      ]}
    >
      {(model, setModel) => (
        <>
          <RelatedList
            title="Categories"
            rows={model.categories}
            headers={["Id", "Name", "Slug"]}
            keyRowAttr="id"
            toCells={(row) => [row.id, row.name, row.slug]}
          />
          <RelatedList
            title="Rates"
            rows={model.rates}
            headers={[
              "Id",
              "Created",
              "Name",
              "Unit Amount",
              "Surcharge",
              "Unit Offset",
              "Undiscounted Amount",
              "Undiscounted Surcharge",
            ]}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              dayjs(row.createdAt).format("lll"),
              row.name,
              <Money key="unit_amount">{row.unitAmount}</Money>,
              <Money key="surcharge">{row.surcharge}</Money>,
              row.unitOffset,
              <Money key="undiscounted_amount">{row.undiscountedAmount}</Money>,
              <Money key="undiscounted_surcharge">{row.undiscountedSurcharge}</Money>,
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
