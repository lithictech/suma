import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import RoleForm from "./RoleForm";
import React from "react";

export default function RoleCreatePage() {
  const empty = { name: "" };
  return <ResourceCreate empty={empty} apiCreate={api.createRole} Form={RoleForm} />;
}
