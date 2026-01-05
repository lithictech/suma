import api from "../api";
import AdminLink from "../components/AdminLink";
import BackTo from "../components/BackTo";
import Link from "../components/Link";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import { resourceEditRoute } from "../modules/resourceRoutes";
import Money from "../shared/react/Money";
import React from "react";

export default function OfferingProductDetailPage() {
  return (
    <ResourceDetail
      resource="offering_product"
      apiGet={api.getCommerceOfferingProduct}
      canEdit={(m) => !m.closedAt}
      canDelete={(m) => !m.closedAt}
      backTo={BackTo.BACK}
      apiSoftDelete={api.closeCommerceOfferingProduct}
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
        model.closedAt && {
          label: "Edit",
          value: (
            <Link to={resourceEditRoute("offering_product", model)}>
              Reopen and Change Price
            </Link>
          ),
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
