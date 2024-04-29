import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import OrganizationMembershipForm from "./OrganizationMembershipForm";
import React from "react";

export default function OrganizationMembershipEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getOrganizationMembership}
      apiUpdate={api.updateOrganizationMembership}
      Form={OrganizationMembershipForm}
    />
  );
}
