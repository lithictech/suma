import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import MemberForm from "./MemberForm";
import React from "react";

export default function MemberEditPage() {
  return (
    <ResourceEdit apiGet={api.getMember} apiUpdate={api.updateMember} Form={MemberForm} />
  );
}
