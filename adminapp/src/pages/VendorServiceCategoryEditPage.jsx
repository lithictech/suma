import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import VendorServiceCategoryForm from "./VendorServiceCategoryForm";
import React from "react";

export default function VendorServiceCategoryEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getVendorServiceCategory}
      apiUpdate={api.updateVendorServiceCategory}
      Form={VendorServiceCategoryForm}
    />
  );
}
