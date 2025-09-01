import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import ProgramPricingForm from "./ProgramPricingForm";
import React from "react";

export default function ProgramPricingEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getProgramPricing}
      apiUpdate={api.updateProgramPricing}
      Form={ProgramPricingForm}
    />
  );
}
