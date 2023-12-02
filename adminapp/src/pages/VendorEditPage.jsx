import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import VendorForm from "./VendorForm";
import React from "react";
import { useParams } from "react-router-dom";

export default function VendorEditPage() {
  return (
    <ResourceEdit apiGet={api.getVendor} apiUpdate={api.updateVendor} Form={VendorForm} />
  );
}
