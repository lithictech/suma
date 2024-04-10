import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import OrganizationForm from "./OrganizationForm";
import React from "react";

export default function OrganizationEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getOrganization}
      apiUpdate={api.updateOrganization}
      Form={OrganizationForm}
    />
  );
}
