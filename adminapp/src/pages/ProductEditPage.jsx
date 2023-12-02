import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import ProductForm from "./ProductForm";
import React from "react";
import { useParams } from "react-router-dom";

export default function ProductEditPage() {
  const { id } = useParams();
  return (
    <ResourceEdit
      id={Number(id)}
      apiGet={api.getCommerceProduct}
      apiUpdate={api.updateCommerceProduct}
      Form={ProductForm}
    />
  );
}
