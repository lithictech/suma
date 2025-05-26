import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditActivityList from "../components/AuditActivityList";
import InlineEditField from "../components/InlineEditField";
import Programs from "../components/Programs";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { useUser } from "../hooks/user";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import MarketingSmsCampaignCreatePage from "./MarketingSmsCampaignCreatePage";
import { Switch } from "@mui/material";
import React from "react";

export default function MarketingSmsCampaignDetailPage() {
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
      resource="marketing_sms_campaign"
      apiGet={api.getMarketingSmsCampaign}
      canEdit
      properties={(model, replaceModel) => [
        { label: "ID", value: model.id },
        { label: "Label", value: model.label },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Created By",
          value: <AdminLink model={model.createdBy}>{model.createdBy?.name}</AdminLink>,
        },
        { label: "Sent At", value: formatDate(model.sentAt) },
        { label: "English Body", value: model.body.en },
        {
          label: "English Payload",
          value: `${model.preview.enPayload.characters} characters, ${model.preview.enPayload.segments} segments, $${model.preview.enPayload.cost} per SMS`,
        },
        { label: "Spanish Body", value: model.body.es },
        {
          label: "Spanish Payload",
          value: `${model.preview.esPayload.characters} characters, ${model.preview.esPayload.segments} segments, $${model.preview.esPayload.cost} per SMS`,
        },
      ]}
    >
      {(model, setModel) => [
        <RelatedList
          title="Lists"
          rows={model.lists}
          keyRowAttr="id"
          headers={["Id", "Label"]}
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="label" model={row}>
              {row.label}
            </AdminLink>,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
