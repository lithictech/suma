import api from "../api";
import AsyncContent from "../components/AsyncContent.tsx";
import OrderDetail from "../components/OrderDetail";
import useAsyncFetch from "../state/useAsyncFetch";
import BreadcrumbBack from "../ui/BreadcrumbBack";
import Page from "../ui/Page.tsx";
import React from "react";
import { useLocation, useParams } from "react-router-dom";

export default function OrderHistoryDetail() {
  const { id } = useParams();
  const location = useLocation();
  const getOrderDetails = React.useCallback(() => api.getOrderDetails({ id }), [id]);
  const { state, replaceState, loading, error } = useAsyncFetch<DetailedOrderHistory>(
    getOrderDetails,
    {
      default: {} as DetailedOrderHistory,
      pickData: true,
      pullFromState: "order",
      location,
    }
  );
  return (
    <Page>
      <BreadcrumbBack back />
      <AsyncContent loading={loading} error={error}>
        <OrderDetail order={state} setOrder={replaceState} />
      </AsyncContent>
    </Page>
  );
}
