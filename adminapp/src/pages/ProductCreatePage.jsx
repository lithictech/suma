import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { stub } from "../modules/formHelpers";
import ProductForm from "./ProductForm";
import React from "react";

export default function ProductCreatePage() {
  const product = {
    image: null,
    imageCaption: stub.translation,
    description: stub.translation,
    name: stub.translation,
    vendor: null,
    ordinal: 0,
    vendorServiceCategories: stub.collection,
    inventory: {
      maxQuantityPerMemberPerOrder: null,
      limitedQuantity: false,
      quantityOnHand: 0,
      quantityPendingFulfillment: 0,
    },
  };

  return (
    <ResourceCreate
      empty={product}
      apiCreate={api.createCommerceProduct}
      Form={ProductForm}
    />
  );
}
