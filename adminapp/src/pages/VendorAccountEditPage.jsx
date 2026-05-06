import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import VendorAccountForm from "./VendorAccountForm";
import React from "react";

export default function VendorAccountEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getVendorAccount}
      apiUpdate={api.updateVendorAccount}
      Form={VendorAccountForm}
    />
  );
}
