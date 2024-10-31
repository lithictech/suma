import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import Link from "../components/Link";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import useRoleAccess from "../hooks/useRoleAccess";
import { dayjs, dayjsOrNull } from "../modules/dayConfig";
import createRelativeUrl from "../shared/createRelativeUrl";
import ListAltIcon from "@mui/icons-material/ListAlt";
import React from "react";

export default function OrganizationDetailPage() {
  const { canWriteResource } = useRoleAccess();
  return (
    <ResourceDetail
      resource="organization"
      apiGet={api.getOrganization}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Updated At", value: dayjs(model.updatedAt) },
        { label: "Name", value: model.name },
        canWriteResource("member") && {
          label: "Enroll in program",
          value: (
            <Link
              to={createRelativeUrl(`/program-enrollment/new`, {
                organizationId: model.id,
                organizationLabel: `(${model.id}) ${model.name}`,
              })}
            >
              <ListAltIcon sx={{ verticalAlign: "middle", marginRight: "5px" }} />
              Enroll in program
            </Link>
          ),
        },
      ]}
    >
      {(model) => (
        <>
          <RelatedList
            title="Program Enrollments"
            headers={["Id", "Program", "Program Active", "Approved At", "Unenrolled At"]}
            rows={model.programEnrollments}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              <AdminLink model={row.program}>{row.program.name.en}</AdminLink>,
              <BoolCheckmark>{row.programActive}</BoolCheckmark>,
              dayjsOrNull(row.approvedAt)?.format("lll"),
              dayjsOrNull(row.unenrolledAt)?.format("lll"),
            ]}
          />
          <RelatedList
            title={`Memberships (${model.memberships.length})`}
            rows={model.memberships}
            headers={["Id", "Member", "Created At", "Updated At"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink model={row} />,
              <AdminLink key="member" model={row.member}>
                {row.member.name}
              </AdminLink>,
              dayjs(row.createdAt).format("lll"),
              dayjs(row.updatedAt).format("lll"),
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
