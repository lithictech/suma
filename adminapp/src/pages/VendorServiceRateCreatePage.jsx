import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import config from "../config";
import VendorServiceRateForm from "./VendorServiceRateForm.jsx";
import React from "react";

export default function VendorServiceRateCreatePage() {
  const empty = {
    name: "",
    unitAmount: config.defaultZeroMoney,
    surcharge: config.defaultZeroMoney,
    unitOffset: 0,
    localizationKey: "",
    ordinal: 0,
    undiscountedRate: null,
  };
  return (
    <ResourceCreate
      empty={empty}
      apiGet={api.getVendorServiceRate}
      apiCreate={api.createVendorServiceRate}
      Form={VendorServiceRateForm}
    />
  );
}
