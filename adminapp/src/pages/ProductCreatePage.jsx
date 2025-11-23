import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import formHelpers from "../modules/formHelpers";
import ProductForm from "./ProductForm";
import React from "react";

export default function ProductCreatePage() {
  const product = {
    image: null,
    imageCaption: formHelpers.initialTranslation,
    description: formHelpers.initialTranslation,
    name: formHelpers.initialTranslation,
    vendor: null,
    ordinal: 0,
    category: null,
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
