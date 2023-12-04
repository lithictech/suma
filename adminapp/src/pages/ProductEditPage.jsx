import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import ProductForm from "./ProductForm";
import React from "react";
import { useParams } from "react-router-dom";

export default function ProductEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getCommerceProduct}
      apiUpdate={api.updateCommerceProduct}
      Form={ProductForm}
    />
  );
}
