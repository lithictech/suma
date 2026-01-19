import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import OfferingProductForm from "./OfferingProductForm";
import React from "react";

export default function OfferingProductEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getCommerceOfferingProduct}
      apiUpdate={api.updateCommerceOfferingProduct}
      Form={OfferingProductForm}
      alwaysApply
    />
  );
}
