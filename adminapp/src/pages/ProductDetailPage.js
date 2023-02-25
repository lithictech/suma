import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress } from "@mui/material";
import isEmpty from "lodash/isEmpty";
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
  const { state: product, loading: productLoading } = useAsyncFetch(getCommerceProduct, {
    default: {},
    pickData: true,
  });
  return (
    <>
      {productLoading && <CircularProgress />}
      {!isEmpty(product) && (
        <div>
          <DetailGrid
            title={`Product ${id}`}
            properties={[
              { label: "ID", value: id },
              { label: "Created At", value: dayjs(product.createdAt) },
              { label: "Name", value: product.name },
              { label: "Vendor", value: product.vendor?.name },
              { label: "Our Cost", value: <Money>{product.ourCost}</Money> },
              { label: "Max Per Offering", value: product.maxQuantityPerOffering },
              { label: "Max Per Order", value: product.maxQuantityPerOrder },
            ]}
          />
          <RelatedList
            title="Orders"
            rows={product.orders}
            headers={["Id", "Created At", "Status", "Member"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              row.orderStatus,
              <AdminLink key="member" model={row.member}>
                {row.member.name}
              </AdminLink>,
            ]}
          />
          <RelatedList
            title={`Offering Products`}
            rows={product.offeringProducts}
            headers={["Id", "Customer Price", "Full Price", "Offering", "Closed"]}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              <Money key="customer_price">{row.customerPrice}</Money>,
              <Money key="undiscounted_price">{row.undiscountedPrice}</Money>,
              <AdminLink key="offering" model={row.offering}>
                {row.offering.description}
              </AdminLink>,
              row.isClosed ? dayjs(row.closedAt).format("lll") : "",
            ]}
          />
        </div>
      )}
    </>
  );
}
