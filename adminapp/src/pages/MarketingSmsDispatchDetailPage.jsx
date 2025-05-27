import api from "../api";
import AdminLink from "../components/AdminLink";
import InlineEditField from "../components/InlineEditField";
import ResourceDetail from "../components/ResourceDetail";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { useUser } from "../hooks/user";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import MarketingSmsCampaignCreatePage from "./MarketingSmsCampaignCreatePage";
import { Button, CircularProgress, Stack, Switch } from "@mui/material";
import React from "react";
import { useParams } from "react-router-dom";

export default function MarketingSmsDispatchDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { isBusy, busy, notBusy } = useBusy();
  const { id } = useParams();

  function handleCancelClick(e, setModel) {
    e.preventDefault();
    busy();
    api
      .cancelMarketingSmsDispatch({ id })
      .then((r) => setModel(r.data))
      .catch(enqueueErrorSnackbar)
      .finally(notBusy);
  }

  if (isBusy) {
    return <CircularProgress />;
  }

  return (
    <ResourceDetail
      resource="marketing_sms_dispatch"
      apiGet={api.getMarketingSmsDispatch}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Campaign",
          value: (
            <AdminLink model={model.smsCampaign}>{model.smsCampaign.label}</AdminLink>
          ),
        },
        {
          label: "Member",
          value: <AdminLink model={model.member}>{model.member.name}</AdminLink>,
        },
        { label: "Status", value: model.status },
        { label: "Sent At", value: formatDate(model.sentAt) },
        { label: "Transport Message ID", value: model.transportMessageId },
      ]}
    >
      {(model, setModel) => [
        model.canCancel && (
          <div>
            <Button
              variant="contained"
              fullWidth={false}
              onClick={(e) => handleCancelClick(e, setModel)}
            >
              Cancel
            </Button>
          </div>
        ),
      ]}
    </ResourceDetail>
  );
}
