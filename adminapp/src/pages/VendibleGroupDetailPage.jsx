import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import SumaImage from "../shared/react/SumaImage";
import React from "react";

export default function VendibleGroupDetailPage() {
  return (
    <ResourceDetail
      apiGet={api.getVendibleGroup}
      title={(model) => `Vendible Group ${model.id}`}
      toEdit={(model) => `/vendible-group/${model.id}/edit`}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Name EN", value: model.name.en },
        { label: "Name ES", value: model.name.es },
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
            title={`Vendibles Displayed (Dashboard)`}
            rows={model.vendibles}
            headers={["Image", "Name EN", "Name ES", "Until", "App Relative Link"]}
            keyRowAttr="key"
            toCells={(row) => [
              <SumaImage
                image={row.image}
                alt={row.image.name}
                className="w-100"
                params={{ crop: "center" }}
                h={50}
                width={50}
              />,
              row.name.en,
              row.name.es,
              dayjs(row.until).format("lll"),
              row.link,
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
