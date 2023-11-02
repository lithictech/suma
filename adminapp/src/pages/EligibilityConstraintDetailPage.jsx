import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress } from "@mui/material";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useParams } from "react-router-dom";

export default function EligibilityConstraintDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getConstraint = React.useCallback(() => {
    return api.getEligibilityConstraint({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const { state: xaction, loading: xactionLoading } = useAsyncFetch(getConstraint, {
    default: {},
    pickData: true,
  });

  return (
    <>
      {xactionLoading && <CircularProgress />}
      {!isEmpty(xaction) && (
        <div>
          <DetailGrid
            title={`Eligibility Constraint ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Created At", value: dayjs(xaction.createdAt) },
              { label: "Name", value: xaction.name },
            ]}
          />
          <RelatedList
            title="Offerings"
            rows={xaction.offerings}
            keyRowAttr="id"
            headers={["Id", "Created", "Description", "Opens", "Closes"]}
            toCells={(row) => [
              <AdminLink key={row.id} model={row}>
                {row.id}
              </AdminLink>,
              dayjs(row.createdAt).format("lll"),
              <AdminLink key={row.id} model={row}>
                {row.description}
              </AdminLink>,
              dayjs(row.opensAt).format("lll"),
              dayjs(row.closesAt).format("lll"),
            ]}
          />
          <RelatedList
            title="Vendor Services"
            rows={xaction.services}
            keyRowAttr="id"
            headers={["Id", "Created", "Vendor", "Name"]}
            toCells={(row) => [
              row.id,
              dayjs(row.createdAt).format("lll"),
              <AdminLink key={row.id} model={row.vendor}>
                {row.vendor.name}
              </AdminLink>,
              row.name,
            ]}
          />
          <RelatedList
            title="Vendor Configurations"
            rows={xaction.configurations}
            keyRowAttr="id"
            headers={[
              "Id",
              "Created",
              "Vendor",
              "App Install Link",
              "Uses Email",
              "Uses SMS",
              "Enabled",
            ]}
            toCells={(row) => [
              row.id,
              dayjs(row.createdAt).format("lll"),
              <AdminLink key={row.vendor.name} model={row.vendor}>
                {row.vendor.name}
              </AdminLink>,
              <SafeExternalLink key={1} href={row.appInstallLink}>
                {row.appInstallLink}
              </SafeExternalLink>,
              row.usesEmail ? "Yes" : "No",
              row.usesSms ? "Yes" : "No",
              row.enabled ? "Yes" : "No",
            ]}
          />
        </div>
      )}
    </>
  );
}
