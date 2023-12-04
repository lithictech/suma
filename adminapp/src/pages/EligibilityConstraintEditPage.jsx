import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import EligibilityConstraintForm from "./EligibilityConstraintForm";
import React from "react";

export default function EligibilityConstraintEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getEligibilityConstraint}
      apiUpdate={api.updateEligibilityConstraint}
      Form={EligibilityConstraintForm}
    />
  );
}
