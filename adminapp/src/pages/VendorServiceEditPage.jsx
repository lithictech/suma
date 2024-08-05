import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import VendorServiceForm from "./VendorServiceForm.jsx";
import React from "react";

export default function VendorServiceEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getVendorService}
      apiUpdate={api.updateVendorService}
      Form={VendorServiceForm}
    />
  );
}
