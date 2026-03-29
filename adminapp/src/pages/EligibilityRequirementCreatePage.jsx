import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import EligibilityRequirementForm from "./EligibilityRequirementForm";
import React from "react";

export default function EligibilityRequirementCreatePage() {
  const empty = { programs: [], paymentTriggers: [] };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createEligibilityRequirement}
      Form={EligibilityRequirementForm}
    />
  );
}
