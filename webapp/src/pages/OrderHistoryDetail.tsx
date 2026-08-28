import api from "../api";
import AppNav from "../components/AppNav.tsx";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import OrderDetail from "../components/OrderDetail";
import PageLoader from "../components/PageLoader";
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

  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (loading) {
    return <PageLoader />;
  }
  return (
    <Page>
      <Page buffer gap={3}>
        <BreadcrumbBack back />
        <OrderDetail order={state} setOrder={replaceState} />
      </Page>
      <AppNav />
    </Page>
  );
}
