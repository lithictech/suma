import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import EligibilityAssignmentForm from "./EligibilityAssignmentForm";
import React from "react";

export default function EligibilityAssignmentCreatePage() {
  const empty = { attribute: {} };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createEligibilityAssignment}
      Form={EligibilityAssignmentForm}
    />
  );
}
