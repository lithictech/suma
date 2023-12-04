import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import config from "../config";
import OfferingProductForm from "./OfferingProductForm";
import React from "react";

export default function OfferingProductCreatePage() {
  const empty = {
    offering: null,
    product: null,
    customerPrice: config.defaultZeroMoney,
    undiscountedPrice: config.defaultZeroMoney,
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createCommerceOfferingProduct}
      Form={OfferingProductForm}
    />
  );
}
