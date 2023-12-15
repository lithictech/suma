import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function OfferingProductDetailPage() {
  return (
    <ResourceDetail
      apiGet={api.getCommerceOfferingProduct}
      title={(model) => `Offering Product ${model.id}`}
      toEdit={(model) => `/offering-product/${model.id}/edit?edit=true`}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Offering",
          value: (
            <AdminLink key={model.offering.id} model={model.offering}>
              {model.offering.description.en}
            </AdminLink>
          ),
        },
        {
          label: "Product",
          value: (
            <AdminLink key={model.product.id} model={model.product}>
              {model.product.name.en}
            </AdminLink>
          ),
        },
        {
          label: "Customer Price",
          value: <Money>{model.customerPrice}</Money>,
        },
        {
          label: "Undiscounted Price",
          value: <Money>{model.undiscountedPrice}</Money>,
        },
      ]}
    >
      {(model) => (
        <RelatedList
          title={`Orders (${model.orders.length})`}
          rows={model.orders}
          headers={["Id", "Created", "Member", "Items", "Status"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            dayjs(row.createdAt).format("lll"),
            <AdminLink key="mem" model={row.member}>
              {row.member.name}
            </AdminLink>,
            row.totalItemCount,
            row.statusLabel,
          ]}
        />
      )}
    </ResourceDetail>
  );
}
