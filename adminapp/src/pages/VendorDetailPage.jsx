import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import theme from "../theme";
import { CircularProgress } from "@mui/material";
import isEmpty from "lodash/isEmpty";
import map from "lodash/map";
import React from "react";
import { useParams } from "react-router-dom";

export default function VendorDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getVendor = React.useCallback(() => {
    return api.getVendor({ id }).catch((e) => enqueueErrorSnackbar(e));
  }, [id, enqueueErrorSnackbar]);
  const { state: vendor, loading: vendorLoading } = useAsyncFetch(getVendor, {
    default: {},
    pickData: true,
  });
  return (
    <>
      {vendorLoading && <CircularProgress />}
      {!isEmpty(vendor) && (
        <div>
          <DetailGrid
            title={`Vendor ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Created At", value: dayjs(vendor.createdAt) },
              { label: "Name", value: vendor.name },
              { label: "Slug", value: vendor.slug },
            ]}
          />
          <RelatedList
            title="Services"
            rows={vendor.services}
            headers={["Id", "Name", "Eligibility Constraints"]}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              row.name,
              row.eligibilityConstraints.map((ec) => (
                <AdminLink
                  key={ec.name}
                  model={ec}
                  sx={{ marginRight: theme.spacing(1) }}
                >
                  {ec.name}
                </AdminLink>
              )),
            ]}
          />
          <RelatedList
            title="Products"
            rows={vendor.products}
            headers={["Id", "Created", "Name"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              row.name,
              map(row.eligibilityConstraints, "name"),
            ]}
          />
        </div>
      )}
    </>
  );
}
