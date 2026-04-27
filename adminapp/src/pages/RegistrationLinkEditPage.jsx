import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import RegistrationLinkForm from "./RegistrationLinkForm";
import React from "react";

export default function RegistrationLinkEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getOrganizationRegistrationLink}
      apiUpdate={api.updateOrganizationRegistrationLink}
      Form={RegistrationLinkForm}
    />
  );
}
