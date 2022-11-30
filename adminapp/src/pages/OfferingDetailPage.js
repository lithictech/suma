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

export default function OfferingDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getCommerceOffering = React.useCallback(() => {
    return api
      .getCommerceOffering({ id })
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }, [id, enqueueErrorSnackbar]);
  const { state: xaction, loading: xactionLoading } = useAsyncFetch(getCommerceOffering, {
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
              { label: "Created At", value: dayjs(xaction.createdAt) },
              { label: "Opening Date", value: dayjs(xaction.opensAt) },
              { label: "Closing Date", value: dayjs(xaction.closesAt) },
              { label: "Description", value: xaction.description },
            ]}
          />
          <RelatedList
            title={`Offering Products (${xaction.productsAmount})`}
            rows={xaction.offeringProducts}
            headers={[
              "Id",
              "Created",
              "Name",
              "Closed",
              "Customer Price",
              "Undiscounted Price",
            ]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              row.name,
              row.isClosed ? dayjs(row.closedAt).format("lll") : "Available",
              <Money key="customer_price">{row.customerPrice}</Money>,
              <Money key="undiscounted_price">{row.undiscountedPrice}</Money>,
            ]}
          />
          <RelatedList
            title={`Offering Orders (${xaction.ordersAmount})`}
            rows={xaction.offeringOrders}
            headers={[
              "Id",
              "Created",
              "Customer",
              "Status",
              "Fulfillment Status",
              "Checkout Id",
            ]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              row.customerName,
              _.capitalize(row.orderStatus),
              _.capitalize(row.fulfillmentStatus),
              row.checkoutId,
            ]}
          />
        </div>
      )}
    </>
  );
}
