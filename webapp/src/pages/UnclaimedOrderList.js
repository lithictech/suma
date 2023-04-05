import api from "../api";
import AnimatedCheckmark from "../components/AnimatedCheckmark";
import ErrorScreen from "../components/ErrorScreen";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import OrderDetail from "../components/OrderDetail";
import PageLoader from "../components/PageLoader";
import { mdp, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { Stack } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Modal from "react-bootstrap/Modal";
import { Link } from "react-router-dom";

export default function UnclaimedOrderList() {
  const [claimedOrder, setClaimedOrder] = React.useState({});
  const {
    state: orderHistory,
    replaceState,
    loading,
    error,
  } = useAsyncFetch(api.getUnclaimedOrderHistory, {
    default: {},
    pickData: true,
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
  const handleOrderClaim = (o) => {
    setClaimedOrder(o);
    replaceState({ items: orderHistory.items.filter((item) => item.id !== o.id) });
  };
  return (
    <>
      <LayoutContainer top gutters>
        <LinearBreadcrumbs back />
        <h2>{t("food:unclaimed_order_history_title")}</h2>
        <p className="text-secondary">{t("food:unclaimed_order_history_intro")}</p>
      </LayoutContainer>
      <hr />
      <Modal show={!isEmpty(claimedOrder)} onHide={() => setClaimedOrder({})}>
        <Modal.Header closeButton>
          <Modal.Title>{t("food:order_claimed")}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <div className="mt-4 text-center d-flex justify-content-center align-items-center flex-column">
            <ScrollTopOnMount />
            <AnimatedCheckmark scale={2} />
            <p className="mt-2 fs-4 w-75">
              {t("food:order_for_claimed_on", {
                serial: claimedOrder.serial,
                fulfilledAt: dayjs(claimedOrder.fulfilledAt).format("lll"),
              })}
            </p>
            <div className="d-flex justify-content-end mt-2">
              <Button
                variant="outline-primary"
                className="mt-2"
                onClick={() => setClaimedOrder({})}
              >
                {t("common:close")}
              </Button>
            </div>
          </div>
        </Modal.Body>
      </Modal>
      {!isEmpty(orderHistory?.items) && (
        <Stack>
          {orderHistory?.items.map((o) => (
            <div key={o.id}>
              <OrderDetail state={o} onOrderClaim={(o) => handleOrderClaim(o)} />
              <hr className="my-4" />
            </div>
          ))}
        </Stack>
      )}
      {isEmpty(orderHistory?.items) && (
        <LayoutContainer gutters>
          {mdp("food:no_unclaimed_orders")}
          <p>
            <Link to="/food">
              {t("food:checkout_available")}
              <i className="bi bi-arrow-right ms-1"></i>
            </Link>
          </p>
        </LayoutContainer>
      )}
    </>
  );
}