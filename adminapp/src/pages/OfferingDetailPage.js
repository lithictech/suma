import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import Link from "../components/Link";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import ListAltIcon from "@mui/icons-material/ListAlt";
import { CircularProgress } from "@mui/material";
import { makeStyles } from "@mui/styles";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useParams } from "react-router-dom";

export default function OfferingDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  const classes = useStyles();
  id = Number(id);
  const getCommerceOffering = React.useCallback(() => {
    return api.getCommerceOffering({ id }).catch((e) => enqueueErrorSnackbar(e));
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
      {!isEmpty(offering) && (
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
          {!isEmpty(offering.orders) && (
            <Link
              to={`/offering/${offering.id}/picklist`}
              sx={{ display: "inline-block", marginTop: "15px" }}
            >
              <ListAltIcon sx={{ verticalAlign: "middle", paddingRight: "5px" }} />
              Pick/Pack List
            </Link>
          )}
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

const useStyles = makeStyles(() => ({
  closed: {
    opacity: 0.5,
  },
}));
