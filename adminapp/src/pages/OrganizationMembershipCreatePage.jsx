import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import OrganizationMembershipForm from "./OrganizationMembershipForm";
import React from "react";

export default function OrganizationMembershipCreatePage() {
  const empty = { unverifiedOrganizationName: "", membershipType: "unverified" };

  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createOrganizationMembership}
      Form={OrganizationMembershipForm}
    />
  );
}
