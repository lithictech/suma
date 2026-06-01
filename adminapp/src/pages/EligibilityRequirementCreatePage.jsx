import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { stub } from "../modules/formHelpers";
import EligibilityRequirementForm from "./EligibilityRequirementForm";
import React from "react";

export default function EligibilityRequirementCreatePage() {
  const empty = {
    programs: stub.collection,
    paymentTriggers: stub.collection,
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createEligibilityRequirement}
      Form={EligibilityRequirementForm}
    />
  );
}
