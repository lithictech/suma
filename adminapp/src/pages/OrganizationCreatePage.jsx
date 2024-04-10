import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import OrganizationForm from "./OrganizationForm";
import React from "react";

export default function OrganizationCreatePage() {
  const empty = { name: "" };

  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createOrganization}
      Form={OrganizationForm}
    />
  );
}
