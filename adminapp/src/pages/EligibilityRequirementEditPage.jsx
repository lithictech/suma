import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import EligibilityAttributeCreatePage from "./EligibilityAttributeCreatePage";
import EligibilityRequirementCreatePage from "./EligibilityRequirementCreatePage";
import EligibilityRequirementForm from "./EligibilityRequirementForm";
import VendorForm from "./VendorForm";
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
