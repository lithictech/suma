import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import formHelpers from "../modules/formHelpers";
import OrganizationForm from "./OrganizationForm";
import React from "react";

export default function OrganizationCreatePage() {
  const empty = {
    name: "",
    ordinal: 0,
    membershipVerificationEmail: "",
    membershipVerificationFrontTemplateId: "",
    membershipVerificationMemberOutreachTemplate: formHelpers.initialTranslation,
    roles: [],
  };

  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createOrganization}
      Form={OrganizationForm}
    />
  );
}
