import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import ProductForm from "./ProductForm";
import React from "react";

export default function ProductEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getCommerceProduct}
      apiUpdate={api.updateCommerceProduct}
      expand={["vendor_service_categories"]}
      Form={ProductForm}
    />
  );
}
