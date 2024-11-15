import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import ProgramForm from "./ProgramForm";
import React from "react";

export default function ProgramEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getProgram}
      apiUpdate={api.updateProgram}
      Form={ProgramForm}
    />
  );
}
