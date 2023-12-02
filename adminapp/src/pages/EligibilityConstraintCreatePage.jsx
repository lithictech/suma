import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import React from "react";
import EligibilityConstraintForm from "./EligibilityConstraintForm";

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
