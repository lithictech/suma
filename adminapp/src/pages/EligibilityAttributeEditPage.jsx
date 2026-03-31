import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import EligibilityAttributeForm from "./EligibilityAttributeForm";
import React from "react";

export default function EligibilityAttributeEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getEligibilityAttribute}
      apiUpdate={api.updateEligibilityAttribute}
      Form={EligibilityAttributeForm}
    />
  );
}
