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

export default function CommerceOfferingDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getBookTransaction = React.useCallback(() => {
    return api
      .getCommerceOffering({ id })
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }, [id, enqueueErrorSnackbar]);
  const { state: xaction, loading: xactionLoading } = useAsyncFetch(getBookTransaction, {
    default: {},
    pickData: true,
  });
  return (
    <>
      {xactionLoading && <CircularProgress />}
      {!_.isEmpty(xaction) && (
        <div>
          <DetailGrid
            title={`Offering ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Closing Date", value: dayjs(xaction.closesAt) },
              { label: "Description", value: xaction.description },
            ]}
          />
          <RelatedList
            title={`Offering Products (${xaction.productsAmount})`}
            rows={xaction.offeringProducts}
            headers={["Id", "Created", "Closed", "Customer Price", "Undiscounted Price"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              row.isClosed ? dayjs(row.closedAt).format("lll") : "Not closed",
              <Money key="customer_price">{row.customerPrice}</Money>,
              <Money key="undiscounted_price">{row.undiscountedPrice}</Money>,
            ]}
          />
        </div>
      )}
    </>
  );
}
