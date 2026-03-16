import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import formHelpers from "../modules/formHelpers";
import EligibilityRequirementForm from "./EligibilityRequirementForm";
import VendorForm from "./VendorForm";
import React from "react";

export default function EligibilityRequirementCreatePage() {
  const empty = {};
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createEligibilityRequirement}
      Form={EligibilityRequirementForm}
    />
  );
}
