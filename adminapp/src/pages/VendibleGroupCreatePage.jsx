import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import formHelpers from "../modules/formHelpers";
import VendibleGroupForm from "./VendibleGroupForm";
import React from "react";

export default function VendibleGroupCreatePage() {
  const empty = {
    name: formHelpers.initialTranslation,
    vendorServices: [],
    commerceOfferings: [],
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createVendibleGroup}
      Form={VendibleGroupForm}
    />
  );
}
