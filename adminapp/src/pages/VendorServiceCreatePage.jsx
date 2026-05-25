import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { dayjs } from "../modules/dayConfig";
import { stub } from "../modules/formHelpers";
import VendorServiceForm from "./VendorServiceForm.jsx";
import React from "react";

export default function VendorServiceCreatePage() {
  const empty = {
    internalName: "",
    externalName: "",
    vendor: { name: "" },
    categories: stub.collection,
    mobilityAdapterSetting: "no_adapter",
    periodBegin: dayjs().format(),
    periodEnd: dayjs().add(1, "day").format(),
  };
  return (
    <ResourceCreate
      empty={empty}
      apiGet={api.getVendorService}
      apiCreate={api.createVendorService}
      Form={VendorServiceForm}
    />
  );
}
