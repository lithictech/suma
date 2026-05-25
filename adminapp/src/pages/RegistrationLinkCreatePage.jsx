import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { stub } from "../modules/formHelpers";
import RegistrationLinkForm from "./RegistrationLinkForm";
import React from "react";

export default function RegistrationLinkCreatePage() {
  const empty = {
    intro: stub.translation,
    icalDtstart: null,
    icalDtend: null,
    icalRrule: "",
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createOrganizationRegistrationLink}
      Form={RegistrationLinkForm}
    />
  );
}
