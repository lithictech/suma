import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import VendorServiceForm from "./VendorServiceForm.jsx";
import React from "react";

export default function VendorServiceCreatePage() {
  const empty = {
    internalName: "",
    externalName: "",
    vendor: { name: "" },
    chargeAfterFulfillment: false,
  };
  return (
    <ResourceCreate
      empty={empty}
      apiGet={api.getVendorService}
      apiCreate={api.createVendorService}
      Form={VendorServiceForm}
    />
  );
}
