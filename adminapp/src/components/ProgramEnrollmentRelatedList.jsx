import { dayjsOrNull } from "../modules/dayConfig";
import createRelativeUrl from "../shared/createRelativeUrl";
import AdminLink from "./AdminLink";
import BoolCheckmark from "./BoolCheckmark";
import RelatedList from "./RelatedList";
import React from "react";

export default function ProgramEnrollmentRelatedList({ model, resource, enrollments }) {
  return (
    <RelatedList
      title="Program Enrollments"
      headers={["Id", "Program", "Program Active", "Approved At", "Unenrolled At"]}
      rows={enrollments}
      addNewLabel="Enroll in another program"
      addNewLink={createRelativeUrl(`/program-enrollment/new`, {
        enrolleeType: resource,
        enrolleeId: model.id,
        enrolleeLabel: `(${model.id}) ${model.name}`,
      })}
      addNewRole={resource}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        <AdminLink model={row.program}>{row.program.name.en}</AdminLink>,
        <BoolCheckmark>{row.programActive}</BoolCheckmark>,
        dayjsOrNull(row.approvedAt)?.format("lll"),
        dayjsOrNull(row.unenrolledAt)?.format("lll"),
      ]}
    />
  );
}
