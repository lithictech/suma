import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
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
            title="Vendor Services"
            rows={xaction.services}
            headers={["Id", "Created", "Name"]}
            keyRowAttr="id"
            toCells={(row) => [row.id, dayjs(row.createdAt).format("lll"), row.name]}
          />
          <RelatedList
            title="Offerings"
            headers={["Id", "Created", "Description", "Opens", "Closes"]}
            rows={xaction.offerings}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key={row.id} model={row}>
                {row.id}
              </AdminLink>,
              dayjs(row.createdAt).format("lll"),
              row.description,
              dayjs(row.opensAt).format("lll"),
              dayjs(row.closesAt).format("lll"),
            ]}
          />
        </div>
      )}
    </>
  );
}
