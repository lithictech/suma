import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import EligibilityAssignmentForm from "./EligibilityAssignmentForm";
import React from "react";

export default function EligibilityAttributeEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getEligibilityAssignment}
      apiUpdate={api.updateEligibilityAssignment}
      Form={EligibilityAssignmentForm}
    />
  );
}
