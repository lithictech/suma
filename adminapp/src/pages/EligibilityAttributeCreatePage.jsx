import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import EligibilityAttributeForm from "./EligibilityAttributeForm";
import React from "react";

export default function EligibilityAttributeCreatePage() {
  const empty = { name: "", description: "" };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createEligibilityAttribute}
      Form={EligibilityAttributeForm}
    />
  );
}
