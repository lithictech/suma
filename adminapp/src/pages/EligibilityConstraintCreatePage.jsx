import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import EligibilityConstraintForm from "./EligibilityConstraintForm";
import React from "react";

export default function EligibilityConstraintCreatePage() {
  const empty = { name: "" };

  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createEligibilityConstraint}
      Form={EligibilityConstraintForm}
    />
  );
}
