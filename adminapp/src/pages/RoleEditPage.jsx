import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import RoleForm from "./RoleForm";
import React from "react";

export default function RoleEditPage() {
  return <ResourceEdit apiGet={api.getRole} apiUpdate={api.updateRole} Form={RoleForm} />;
}
