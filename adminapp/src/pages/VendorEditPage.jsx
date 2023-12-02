import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import ResourceEdit from "../components/ResourceEdit";
import ProductForm from "./ProductForm";
import VendorForm from "./VendorForm";
import React from "react";
import { useParams } from "react-router-dom";

export default function VendorEditPage() {
  const { id } = useParams();
  return (
    <ResourceEdit
      id={Number(id)}
      apiGet={api.getVendor}
      apiUpdate={api.updateVendor}
      Form={VendorForm}
    />
  );
}
