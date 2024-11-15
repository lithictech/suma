import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import ProgramEnrollmentForm from "./ProgramEnrollmentForm";
import React from "react";

export default function ProgramEnrollmentCreatePage() {
  const empty = {
    program: {},
    member: {},
    organization: {},
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createProgramEnrollment}
      Form={ProgramEnrollmentForm}
    />
  );
}
