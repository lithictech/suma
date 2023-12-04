import api from "../api";
import AdminLink from "../components/AdminLink";
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
    />
  );
}
