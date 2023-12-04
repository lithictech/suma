import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import VendorForm from "./VendorForm";
import React from "react";

export default function VendorEditPage() {
  return (
    <ResourceEdit apiGet={api.getVendor} apiUpdate={api.updateVendor} Form={VendorForm} />
  );
}
