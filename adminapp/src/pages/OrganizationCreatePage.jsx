import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { stub } from "../modules/formHelpers";
import OrganizationForm from "./OrganizationForm";
import React from "react";

export default function OrganizationCreatePage() {
  const empty = {
    name: "",
    ordinal: 0,
    membershipVerificationEmail: "",
    membershipVerificationFrontTemplateId: "",
    membershipVerificationMemberOutreachTemplate: stub.translation,
    roles: stub.collection,
  };

  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createOrganization}
      Form={OrganizationForm}
    />
  );
}
