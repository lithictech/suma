import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import VendorConfigurationForm from "./VendorConfigurationForm";
import React from "react";

export default function VendorConfigurationEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getVendorConfiguration}
      apiUpdate={api.updateVendorConfiguration}
      Form={VendorConfigurationForm}
    />
  );
}
