import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import AnonMemberContactForm from "./AnonMemberContactForm";
import React from "react";

export default function AnonMemberContactEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getAnonMemberContact}
      apiUpdate={api.updateAnonMemberContact}
      Form={AnonMemberContactForm}
    />
  );
}
