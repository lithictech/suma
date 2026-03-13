import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import EligibilityAttributeCreatePage from "./EligibilityAttributeCreatePage";
import VendorForm from "./VendorForm";
import React from "react";

export default function EligibilityAttributeEditPage() {
  return (
    <ResourceEdit apiGet={api.getVendor} apiUpdate={api.updateVendor} Form={VendorForm} />
  );
}
