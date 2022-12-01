import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress } from "@mui/material";
import { makeStyles } from "@mui/styles";
import _ from "lodash";
import React from "react";
import { useParams } from "react-router-dom";

export default function OfferingDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  const classes = useStyles();
  id = Number(id);
  const getCommerceOffering = React.useCallback(() => {
    return api
      .getCommerceOffering({ id })
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }, [id, enqueueErrorSnackbar]);
  const { state: offering, loading: offeringLoading } = useAsyncFetch(
    getCommerceOffering,
    {
      default: {},
      pickData: true,
    }
  );
  return (
    <>
      {offeringLoading && <CircularProgress />}
      {!_.isEmpty(offering) && (
        <div>
          <DetailGrid
            title={`Offering ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Created At", value: dayjs(offering.createdAt) },
              { label: "Opening Date", value: dayjs(offering.opensAt) },
              { label: "Closing Date", value: dayjs(offering.closesAt) },
              { label: "Description", value: offering.description },
            ]}
          />
          <RelatedList
            title={`Products (${offering.offeringProducts.length})`}
            rows={offering.offeringProducts}
            headers={["Id", "Name", "Vendor", "Customer Price", "Full Price"]}
            keyRowAttr="id"
            rowClass={(row) => (row.closedAt ? classes.closed : "")}
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              <AdminLink key="id" model={row}>
                {row.productName}
              </AdminLink>,
              row.vendorName,
              <Money key="customer_price">{row.customerPrice}</Money>,
              <Money key="undiscounted_price">{row.undiscountedPrice}</Money>,
            ]}
          />
          <RelatedList
            title={`Orders (${offering.orders.length})`}
            rows={offering.orders}
            headers={["Id", "Created", "Member", "Items", "Status"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              <AdminLink key="mem" model={row.member}>
                {row.member.name}
              </AdminLink>,
              row.totalItemCount,
              row.statusLabel,
            ]}
          />
        </div>
      )}
    </>
  );
}

const useStyles = makeStyles((theme) => ({
  closed: {
    opacity: 0.5,
  },
}));
