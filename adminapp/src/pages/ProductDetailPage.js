import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress } from "@mui/material";
import _ from "lodash";
import React from "react";
import { useParams } from "react-router-dom";

export default function ProductDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getCommerceProduct = React.useCallback(() => {
    return api
      .getCommerceProduct({ id })
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }, [id, enqueueErrorSnackbar]);
  const { state: xaction, loading: xactionLoading } = useAsyncFetch(getCommerceProduct, {
    default: {},
    pickData: true,
  });
  return (
    <>
      {xactionLoading && <CircularProgress />}
      {!_.isEmpty(xaction) && (
        <div>
          <DetailGrid
            title={`Product ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Created At", value: dayjs(xaction.createdAt) },
              { label: "Name", value: xaction.name },
              { label: "Vendor ID", value: xaction.vendorId },
              { label: "Our Cost", value: <Money>{xaction.ourCost}</Money> },
            ]}
          />
          <RelatedList
            title="Offerings"
            rows={xaction.offerings}
            headers={["Id", "Created At", "Description", "Opens", "Closes"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              <AdminLink key="description" model={row}>
                {row.description}
              </AdminLink>,
              dayjs(row.opensAt).format("lll"),
              dayjs(row.closesAt).format("lll"),
            ]}
          />
        </div>
      )}
    </>
  );
}
