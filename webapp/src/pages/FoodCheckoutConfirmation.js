import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import PageLoader from "../components/PageLoader";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import _ from "lodash";
import React from "react";
import { useLocation, useParams } from "react-router-dom";

export default function FoodCheckoutConfirmation() {
  const { id } = useParams();
  const location = useLocation();
  const getCheckoutConfirmation = React.useCallback(
    () => api.getCheckoutConfirmation({ id }),
    [id]
  );
  const {
    state: checkout,
    loading,
    error,
  } = useAsyncFetch(getCheckoutConfirmation, {
    default: {},
    pickData: true,
    pullFromState: "checkout",
    location,
  });

  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (loading || _.isEmpty(checkout)) {
    return <PageLoader />;
  }

  return <div>Checkout confirmation for {checkout.id}</div>;
}
