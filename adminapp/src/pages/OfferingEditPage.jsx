import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import OfferingForm from "./OfferingForm";
import React from "react";

export default function OfferingEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getCommerceOffering}
      apiUpdate={api.updateCommerceOffering}
      Form={OfferingForm}
    />
  );
}
