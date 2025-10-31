import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import config from "../config";
import VendorServiceCategoryDetailPage from "./VendorServiceCategoryDetailPage";
import VendorServiceCategoryForm from "./VendorServiceCategoryForm";
import VendorServiceRateForm from "./VendorServiceRateForm.jsx";
import React from "react";

export default function VendorServiceCategoryCreatePage() {
  const empty = {
    name: "",
    slug: "",
    parent: null,
  };
  return (
    <ResourceCreate
      empty={empty}
      apiGet={api.getVendorServiceCategory}
      apiCreate={api.createVendorServiceCategory}
      Form={VendorServiceCategoryForm}
    />
  );
}
