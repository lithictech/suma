import api from "../api";
import AdminLink from "../components/AdminLink";
import Link from "../components/Link";
import RelatedListRemote from "../components/RelatedListRemote";
import ResourceDetail from "../components/ResourceDetail";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import createRelativeUrl from "../shared/createRelativeUrl";
import EditIcon from "@mui/icons-material/Edit";
import IconButton from "@mui/material/IconButton";
import React from "react";

export default function EligibilityRequirementDetailPage() {
  return (
    <ResourceDetail
      resource="eligibility_requirement"
      apiGet={api.getEligibilityRequirement}
      apiDelete={api.destroyEligibilityRequirement}
      canEdit
      properties={(model) => [
        ...resourceDetailCommonFields(model),
        {
          label: "Formula",
          value: (
            <>
              <IconButton
                component={Link}
                size="small"
                color="success"
                href={createRelativeUrl(
                  `/eligibility-requirement/${model.id}/edit-expression`
                )}
                sx={{ marginRight: 1 }}
              >
                <EditIcon />
              </IconButton>
              <code>{model.expressionFormulaStr}</code>
            </>
          ),
        },
      ]}
    >
      {(model) => [
        <RelatedListRemote
          title="Programs"
          collection={model.programs}
          addNewLabel="Add program requirement"
          addNewRole="program"
          addNewLink={createRelativeUrl(`/eligibility-requirement/${model.id}/edit`)}
          headers={["Id", "Name"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row} />,
            <AdminLink model={row}>{row.label}</AdminLink>,
          ]}
        />,
        <RelatedListRemote
          title="Payment Triggers"
          collection={model.paymentTriggers}
          addNewLabel="Add payment trigger requirement"
          addNewRole="program"
          addNewLink={createRelativeUrl(`/eligibility-requirement/${model.id}/edit`)}
          headers={["Id", "Name"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row} />,
            <AdminLink model={row}>{row.label}</AdminLink>,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
