import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
import ChargeDetailGrid from "../components/ChargeDetailGrid";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import RelatedListRemote from "../components/RelatedListRemote";
import ResourceDetail from "../components/ResourceDetail";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import Money from "../shared/react/Money";
import React from "react";

export default function OrderDetailPage() {
  return (
    <ResourceDetail
      resource="order"
      title={(model) => `Order ${model.serial}`}
      apiGet={api.getCommerceOrder}
      canEdit={false}
      properties={(model) => [
        ...resourceDetailCommonFields(model),
        {
          label: "Member",
          value: (
            <AdminLink key="member" model={model.member}>
              {model.member.name}
            </AdminLink>
          ),
        },
        {
          label: "Status",
          value: model.statusLabel,
        },
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
              value: model.checkout.paymentInstrument?.label,
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
        <ChargeDetailGrid isDetailGrid model={model.charge} />,
        <RelatedListRemote
          title="Items"
          collection={model.items}
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
