import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import VendorForm from "./VendorForm";
import React from "react";

export default function VendorCreatePage() {
  const empty = { name: "" };

  return <ResourceCreate empty={empty} apiCreate={api.createVendor} Form={VendorForm} />;
}
