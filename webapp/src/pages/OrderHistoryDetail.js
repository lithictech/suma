import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import OrderDetail from "../components/OrderDetail";
import PageLoader from "../components/PageLoader";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import React from "react";
import { useLocation, useParams } from "react-router-dom";

export default function OrderHistoryDetail() {
  const { id } = useParams();
  const location = useLocation();
  const getOrderDetails = React.useCallback(() => api.getOrderDetails({ id }), [id]);
  const { state, replaceState, loading, error } = useAsyncFetch(getOrderDetails, {
    default: {},
    pickData: true,
    pullFromState: "order",
    location,
  });

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
    <>
      <LayoutContainer top gutters>
        <LinearBreadcrumbs back />
      </LayoutContainer>
      <OrderDetail state={state} onOrderClaimed={replaceState} />
    </>
  );
}
