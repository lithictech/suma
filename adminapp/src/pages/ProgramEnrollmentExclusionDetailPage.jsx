import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function ProgramEnrollmentExclusionDetailPage() {
  return (
    <ResourceDetail
      resource="program_enrollment_exclusion"
      apiGet={api.getProgramEnrollmentExclusion}
      apiDelete={api.destroyProgramEnrollmentExclusion}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Created By",
          value: <AdminLink model={model.createdBy}>{model.createdBy?.name}</AdminLink>,
        },
        {
          label: "Program",
          value: <AdminLink model={model.program}>{model.program.name.en}</AdminLink>,
        },
        {
          label: "Member",
          value: <AdminLink model={model.member}>{model.member.name}</AdminLink>,
        },
      ]}
    />
  );
}
