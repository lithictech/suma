import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import VendibleGroupForm from "./VendibleGroupForm";
import React from "react";

export default function VendibleGroupEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getVendibleGroup}
      apiUpdate={api.updateVendibleGroup}
      Form={VendibleGroupForm}
    />
  );
}
