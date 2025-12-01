import api from "../api";
import AdminLink from "../components/AdminLink";
import CategoriesRelatedList from "../components/CategoriesRelatedList";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import detailPageImageProperties from "../components/detailPageImageProperties";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import createRelativeUrl from "../shared/createRelativeUrl";
import Money from "../shared/react/Money";
import React from "react";

export default function ProductDetailPage() {
  return (
    <ResourceDetail
      resource="product"
      apiGet={api.getCommerceProduct}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        ...detailPageImageProperties(model.image),
        { label: "Name (En)", value: model.name.en },
        { label: "Name (Es)", value: model.name.es },
        { label: "Description (En)", value: model.description.en },
        { label: "Description (Es)", value: model.description.es },
        { label: "Ordinal", value: model.ordinal },
        {
          label: "Vendor",
          value: <AdminLink model={model.vendor}>{model.vendor.name}</AdminLink>,
        },
        {
          label: "Max Per Member/Offering",
          value: model.inventory.maxQuantityPerMemberPerOffering,
        },
        { label: "Limited Quantity", value: model.inventory.limitedQuantity },
        { label: "Quantity On Hand", value: model.inventory.quantityOnHand },
        {
          label: "Quantity Pending Fulfillment",
          value: model.inventory.quantityPendingFulfillment,
        },
      ]}
    >
      {(model) => [
        <CategoriesRelatedList categories={model.vendorServiceCategories} />,
        <RelatedList
          title={`Offering Products (${model.offeringProducts?.length})`}
          addNewLabel="Create Offering Product"
          addNewLink={createRelativeUrl("/offering-product/new", {
            productId: model.id,
            productLabel: model.name.en,
          })}
          addNewRole="offering_product"
          rows={model.offeringProducts}
          headers={["Id", "Customer Price", "Full Price", "Offering", "Closed"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key={row.id} model={row} />,
            <Money key="customer_price">{row.customerPrice}</Money>,
            <Money key="undiscounted_price">{row.undiscountedPrice}</Money>,
            <AdminLink key="offering" model={row.offering}>
              {row.offering.description.en}
            </AdminLink>,
            row.isClosed ? dayjs(row.closedAt).format("lll") : "",
          ]}
        />,
        <RelatedList
          title={`Orders (${model.orders?.length})`}
          rows={model.orders}
          headers={["Id", "Created At", "Status", "Member"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            formatDate(row.createdAt),
            row.orderStatus,
            <AdminLink key="member" model={row.member}>
              {row.member.name}
            </AdminLink>,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
