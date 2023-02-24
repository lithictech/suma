import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
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

export default function OrderDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getOrder = React.useCallback(() => {
    return api
      .getCommerceOrder({ id })
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }, [id, enqueueErrorSnackbar]);
  const { state: order, loading: orderLoading } = useAsyncFetch(getOrder, {
    default: {},
    pickData: true,
  });
  const checkout = order.checkout || {};
  return (
    <>
      {orderLoading && <CircularProgress />}
      {!isEmpty(order) && (
        <div>
          <DetailGrid
            title={`Order ${order.serial}`}
            properties={[
              { label: "ID", value: id },
              {
                label: "Member",
                value: (
                  <AdminLink key="member" model={order.member}>
                    {order.member.name}
                  </AdminLink>
                ),
              },
              { label: "Created At", value: dayjs(order.createdAt) },
              {
                label: "Status",
                value: order.statusLabel,
              },
              { label: "Total Paid", value: <Money>{order.paidAmount}</Money> },
              { label: "Total Charged", value: <Money>{order.fundedAmount}</Money> },
            ]}
          />
          <DetailGrid
            title="Checkout Details"
            properties={[
              {
                label: "Undiscounted Cost",
                value: <Money>{checkout.undiscountedCost}</Money>,
              },
              { label: "Customer Cost", value: <Money>{checkout.customerCost}</Money> },
              { label: "Handling", value: <Money>{checkout.handling}</Money> },
              { label: "Tax", value: <Money>{checkout.tax}</Money> },
              { label: "Total", value: <Money>{checkout.total}</Money> },
              { label: "Instrument", value: checkout.paymentInstrument.adminLabel },
              {
                label: "Fulfillment",
                value: <Fulfillment f={checkout.fulfillmentOption} />,
              },
            ]}
          />
          <RelatedList
            title="Items"
            rows={order.items}
            headers={["Quantity", "Product", "Vendor", "Customer Price", "Full Price"]}
            keyRowAttr="id"
            toCells={(row) => [
              row.quantity,
              <AdminLink key="id" model={row.offeringProduct}>
                {row.offeringProduct.productName}
              </AdminLink>,
              row.offeringProduct.vendorName,
              <Money key="customer_price">{row.offeringProduct.customerPrice}</Money>,
              <Money key="undiscounted_price">
                {row.offeringProduct.undiscountedPrice}
              </Money>,
            ]}
          />
          <AuditLogs auditLogs={order.auditLogs} />
        </div>
      )}
    </>
  );
}

function Fulfillment({ f }) {
  return `${f.description}`;
}
