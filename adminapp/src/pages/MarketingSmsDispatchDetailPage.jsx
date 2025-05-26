import api from "../api";
import AdminLink from "../components/AdminLink";
import InlineEditField from "../components/InlineEditField";
import ResourceDetail from "../components/ResourceDetail";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { useUser } from "../hooks/user";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import MarketingSmsCampaignCreatePage from "./MarketingSmsCampaignCreatePage";
import { Switch } from "@mui/material";
import React from "react";

export default function MarketingSmsDispatchDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { user } = useUser();
  const handleUpdateProgramEnrollment = (enrollment, replaceState) => {
    return api
      .updateProgramEnrollment(enrollment)
      .then((r) => replaceState(r.data))
      .catch(enqueueErrorSnackbar);
  };
  return (
    <ResourceDetail
      resource="program_enrollment"
      apiGet={api.getProgramEnrollment}
      properties={(model, replaceModel) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Program Name EN",
          value: <AdminLink model={model.program}>{model.program.name.en}</AdminLink>,
        },
        {
          label: "Program Name ES",
          value: <AdminLink model={model.program}>{model.program.name.es}</AdminLink>,
        },
        {
          label: "Enrolled " + model.enrolleeType,
          value: <AdminLink model={model.enrollee}>{model.enrollee?.name}</AdminLink>,
        },
        {
          label: "Approved",
          children: (
            <InlineEditField
              resource="program_enrollment"
              renderDisplay={formatDate(model.approvedAt)}
              initialEditingState={{ id: model.id }}
              renderEdit={(st, set) => {
                const enrollment = { ...model, ...st };
                return (
                  <Switch
                    checked={enrollment.approved}
                    onChange={(e) =>
                      set({
                        ...st,
                        approved: e.target.checked,
                        approvedBy: e.target.checked ? { id: user.id } : null,
                      })
                    }
                  ></Switch>
                );
              }}
              onSave={(enrollment) =>
                handleUpdateProgramEnrollment(enrollment, replaceModel)
              }
            />
          ),
        },
        {
          label: "Approved By",
          value: <AdminLink model={model.approvedBy}>{model.approvedBy?.name}</AdminLink>,
        },
        {
          label: "Unenrolled",
          children: (
            <InlineEditField
              resource="program_enrollment"
              renderDisplay={formatDate(model.unenrolledAt)}
              initialEditingState={{ id: model.id }}
              renderEdit={(st, set) => {
                const enrollment = { ...model, ...st };
                return (
                  <Switch
                    checked={enrollment.unenrolled}
                    onChange={(e) =>
                      set({
                        ...st,
                        unenrolled: e.target.checked,
                        unenrolledBy: e.target.checked ? { id: user.id } : null,
                      })
                    }
                  ></Switch>
                );
              }}
              onSave={(enrollment) =>
                handleUpdateProgramEnrollment(enrollment, replaceModel)
              }
            />
          ),
        },
        {
          label: "Unenrolled By",
          value: (
            <AdminLink model={model.unenrolledBy}>{model.unenrolledBy?.name}</AdminLink>
          ),
        },
      ]}
    />
  );
}
