import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import formHelpers from "../modules/formHelpers";
import RegistrationLinkForm from "./RegistrationLinkForm";
import React from "react";

export default function RegistrationLinkCreatePage() {
  const empty = {};
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createOrganizationRegistrationLink}
      Form={RegistrationLinkForm}
    />
  );
}
