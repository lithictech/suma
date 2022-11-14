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
  const { state } = useLocation();
  const {
    state: checkout,
    loading,
    error,
    asyncFetch,
  } = useAsyncFetch(api.getCheckoutConfirmation, {
    default: state?.checkout,
    pickData: true,
    doNotFetchOnInit: true,
  });
  React.useEffect(() => {
    if (_.isEmpty(checkout)) {
      asyncFetch({ id });
    }
  }, [asyncFetch, checkout, id]);
  React.useEffect(() => {
    window.history.replaceState({}, document.title);
  }, []);

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
