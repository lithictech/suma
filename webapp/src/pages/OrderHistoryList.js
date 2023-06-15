import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import UnclaimedOrdersWidget from "../components/UnclaimedOrdersWidget";
import { mdp, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import find from "lodash/find";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { Stack } from "react-bootstrap";
import Card from "react-bootstrap/Card";
import { Link, useNavigate } from "react-router-dom";

export default function OrderHistoryList() {
  const {
    state: orderHistory,
    loading,
    error,
  } = useAsyncFetch(api.getOrderHistory, {
    default: {},
    pickData: true,
  });
  const navigate = useNavigate();
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

  function handleNavigate(e, order) {
    const detailed = find(orderHistory.detailedOrders, { id: order.id });
    if (!detailed) {
      return;
    }
    e.preventDefault();
    navigate(`/order/${order.id}`, { state: { order: detailed } });
  }
  return (
    <>
      <UnclaimedOrdersWidget />
      <LayoutContainer top gutters>
        <LinearBreadcrumbs back="/food" />
        <h2>{t("food:order_history_title")}</h2>
      </LayoutContainer>
      <LayoutContainer gutters>
        {!isEmpty(orderHistory?.items) && (
          <Stack gap={4} className="mt-4">
            {orderHistory?.items.map((o) => (
              <Order key={o.id} {...o} onNavigate={(e) => handleNavigate(e, o)} />
            ))}
          </Stack>
        )}
        {isEmpty(orderHistory?.items) && (
          <>
            {mdp("food:no_orders")}
            <p>
              <Link to="/food">
                {t("food:checkout_available")}
                <i className="bi bi-arrow-right ms-1"></i>
              </Link>
            </p>
          </>
        )}
      </LayoutContainer>
    </>
  );
}

function Order({ id, createdAt, total, image, serial, onNavigate, beginFulfillmentAt }) {
  return (
    <Card>
      <Card.Body>
        <Stack direction="horizontal" gap={3}>
          <SumaImage image={image} width={80} h={80} className="border rounded" />
          <div>
            <Card.Link
              as={RLink}
              href={`/order/${id}`}
              className="h5"
              onClick={onNavigate}
            >
              {t("food:order_serial", { serial: serial })}
            </Card.Link>
            <Card.Text className="text-secondary mt-1">
              {beginFulfillmentAt
                ? t("food:order_available_for_pickup", {
                    date: dayjs(beginFulfillmentAt).format("ll"),
                  })
                : t("food:order_date", { date: dayjs(createdAt).format("ll") })}
              <br />
              {t("food:total", { total: total })}
            </Card.Text>
          </div>
        </Stack>
      </Card.Body>
    </Card>
  );
}
