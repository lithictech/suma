import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import ProgramPricingForm from "./ProgramPricingForm";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function ProgramPricingCreatePage() {
  const [searchParams] = useSearchParams();
  const empty = {
    program: {
      id: Number(searchParams.get("programId")),
      label: searchParams.get("programLabel"),
    },
    vendorService: {},
    vendorServiceRate: {},
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createProgramPricing}
      Form={ProgramPricingForm}
    />
  );
}
