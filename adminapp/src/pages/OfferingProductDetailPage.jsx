import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import Money from "../shared/react/Money";
import React from "react";

export default function OfferingProductDetailPage() {
  return (
    <ResourceDetail
      resource="offering_product"
      apiGet={api.getCommerceOfferingProduct}
      canEdit
      apiSoftDelete={api.closeCommerceOfferingProduct}
      canDelete={(m) => !m.closedAt}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Closed At", value: model.closedAt && dayjs(model.closedAt) },
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
      {(model) => [
        <RelatedList
          title={`Orders (${model.orders.length})`}
          rows={model.orders}
          headers={["Id", "Created", "Member", "Items", "Status"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            formatDate(row.createdAt),
            <AdminLink key="mem" model={row.member}>
              {row.member.name}
            </AdminLink>,
            row.totalItemCount,
            row.statusLabel,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
