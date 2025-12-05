import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import { Button, CircularProgress } from "@mui/material";
import React from "react";
import { useParams } from "react-router-dom";

export default function MarketingListDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { isBusy, busy, notBusy } = useBusy();
  const { id } = useParams();

  function handleRebuildClick(e, setModel) {
    e.preventDefault();
    busy();
    api
      .rebuildMarketingList({ id })
      .then((r) => setModel(r.data))
      .catch(enqueueErrorSnackbar)
      .finally(notBusy);
  }

  if (isBusy) {
    return <CircularProgress />;
  }

  return (
    <ResourceDetail
      resource="marketing_list"
      apiGet={api.getMarketingList}
      canEdit={(r) => !r.managed}
      canDelete={(r) => !r.managed}
      apiDelete={api.destroyMarketingList}
      properties={(model, replaceModel) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Label",
          value: model.label,
        },
        {
          label: "Managed",
          value: model.managed ? "Automatic" : "Manual",
        },
      ]}
    >
      {(model, setModel) => [
        model.managed && (
          <div>
            <Button
              variant="contained"
              fullWidth={false}
              onClick={(e) => handleRebuildClick(e, setModel)}
            >
              Rebuild
            </Button>
          </div>
        ),
        <RelatedList
          title="Members"
          rows={model.members}
          headers={["Id", "Name", "Phone"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="name" model={row}>
              {row.name}
            </AdminLink>,
            row.formattedPhone,
          ]}
        />,
        <RelatedList
          title="Broadcasts"
          rows={model.smsBroadcasts}
          headers={["Id", "Label", "Sent At"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="label" model={row}>
              {row.label}
            </AdminLink>,
            formatDate(row.sentAt),
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
