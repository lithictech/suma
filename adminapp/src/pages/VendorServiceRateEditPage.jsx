import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import VendorServiceRateForm from "./VendorServiceRateForm.jsx";
import React from "react";

export default function VendorServiceRateEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getVendorServiceRate}
      apiUpdate={api.updateVendorServiceRate}
      Form={VendorServiceRateForm}
    />
  );
}
