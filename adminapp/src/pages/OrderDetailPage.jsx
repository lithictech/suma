import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function OrderDetailPage() {
  return (
    <ResourceDetail
      resource="order"
      title={(model) => `Order ${model.serial}`}
      apiGet={api.getCommerceOrder}
      properties={(model) => [
        { label: "ID", value: model.id },
        {
          label: "Member",
          value: (
            <AdminLink key="member" model={model.member}>
              {model.member.name}
            </AdminLink>
          ),
        },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Status",
          value: model.statusLabel,
        },
        { label: "Total Paid", value: <Money>{model.paidAmount}</Money> },
        { label: "Total Charged", value: <Money>{model.fundedAmount}</Money> },
      ]}
    >
      {(model) => [
        <DetailGrid
          title="Checkout Details"
          properties={[
            {
              label: "Undiscounted Cost",
              value: <Money>{model.checkout.undiscountedCost}</Money>,
            },
            {
              label: "Customer Cost",
              value: <Money>{model.checkout.customerCost}</Money>,
            },
            { label: "Handling", value: <Money>{model.checkout.handling}</Money> },
            { label: "Tax", value: <Money>{model.checkout.tax}</Money> },
            { label: "Total", value: <Money>{model.checkout.total}</Money> },
            {
              label: "Instrument",
              value: model.checkout.paymentInstrument?.adminLabel,
            },
            {
              label: "Fulfillment (En)",
              value: model.checkout.fulfillmentOption?.description.en,
            },
            {
              label: "Fulfillment (Es)",
              value: model.checkout.fulfillmentOption?.description.es,
            },
          ]}
        />,
        <RelatedList
          title="Items"
          rows={model.items}
          headers={[
            "Quantity",
            "Offering Product",
            "Vendor",
            "Customer Price",
            "Full Price",
          ]}
          keyRowAttr="id"
          toCells={(row) => [
            row.quantity,
            <AdminLink key="id" model={row.offeringProduct}>
              {row.offeringProduct.productName}
            </AdminLink>,
            row.offeringProduct.vendorName,
            <Money key="customer_price">{row.offeringProduct.customerPrice}</Money>,
            <Money key="undiscounted_price">
              {row.offeringProduct.undiscountedPrice}
            </Money>,
          ]}
        />,
        <AuditLogs auditLogs={model.auditLogs} />,
      ]}
    </ResourceDetail>
  );
}
