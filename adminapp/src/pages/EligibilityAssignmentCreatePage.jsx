import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import formHelpers from "../modules/formHelpers";
import EligibilityAssignmentForm from "./EligibilityAssignmentForm";
import VendorForm from "./VendorForm";
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
