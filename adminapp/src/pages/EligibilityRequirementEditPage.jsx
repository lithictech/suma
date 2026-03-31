import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import EligibilityRequirementForm from "./EligibilityRequirementForm";
import React from "react";

export default function EligibilityRequirementEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getEligibilityRequirement}
      apiUpdate={api.updateEligibilityRequirement}
      Form={EligibilityRequirementForm}
    />
  );
}
