import api from "../api";
import AppNav from "../components/AppNav.tsx";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageHeading from "../components/PageHeading";
import PageLoader from "../components/PageLoader";
import SeeAlsoAlert from "../components/SeeAlsoAlert";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import { RoutePath } from "../routing/RoutePath.ts";
import useNavigate from "../routing/useNavigate";
import useAsyncFetch from "../state/useAsyncFetch";
import useUser from "../state/useUser";
import BreadcrumbBack from "../ui/BreadcrumbBack";
import Button from "../ui/Button";
import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import CardText from "../ui/CardText";
import DivLink from "../ui/DivLink.tsx";
import Page from "../ui/Page.tsx";
import Stack from "../ui/Stack";
import find from "lodash/find";
import isEmpty from "lodash/isEmpty";
import React from "react";

export default function OrderHistoryList() {
  const { user } = useUser();
  const {
    state: orderHistory,
    loading,
    error,
  } = useAsyncFetch<OrderHistoryCollection>(api.getOrderHistory, {
    default: {} as OrderHistoryCollection,
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
  function handleNavigate(e: React.MouseEvent, order: SimpleOrderHistory) {
    const detailed = find(orderHistory.detailedOrders, { id: order.id });
    if (!detailed) {
      return;
    }
    e.preventDefault();
    navigate(["/order/:id", { id: order.id }], { state: { order: detailed } });
  }
  return (
    <Page>
      <Page buffer gap={3}>
        {user.unclaimedOrdersCount > 0 && (
          <SeeAlsoAlert
            variant="success"
            label={t("dashboard.claim_orders")}
            iconClass="bi-bag-check-fill"
            alertClass="solo-alert"
            show
            to="/unclaimed-orders"
          />
        )}
        <BreadcrumbBack back="/food" />
        <PageHeading>{t("food.order_history_title")}</PageHeading>
        {loading ? (
          <PageLoader />
        ) : !isEmpty(orderHistory?.items) ? (
          <Stack col gap={3}>
            {orderHistory?.items.map((o) => (
              <Order
                key={o.id}
                {...o}
                onNavigate={(e: React.MouseEvent) => handleNavigate(e, o)}
              />
            ))}
          </Stack>
        ) : (
          <>
            {t("food.no_orders")}
            <div className="button-stack mt-2">
              <Button variant="primary" href="/food">
                {t("food.available_offerings")}
              </Button>
            </div>
          </>
        )}
      </Page>
      <AppNav />
    </Page>
  );
}

interface OrderProps extends SimpleOrderHistory {
  onNavigate: (e: React.MouseEvent) => void;
}

function Order({
  id,
  createdAt,
  total,
  image,
  serial,
  fulfilledAt,
  onNavigate,
  availableForPickupAt,
}: OrderProps) {
  return (
    <Card>
      <CardBody>
        <DivLink to={`/order/${id}` as RoutePath} onClick={onNavigate}>
          <Stack row gap={3}>
            <SumaImage image={image} width={80} height={80} className="border-radius" />
            <Stack col gap={2}>
              <CardText variant="title">
                {t("food.order_serial", { serial: serial })}
              </CardText>
              <CardText variant="subtitle">
                {fulfilledAt
                  ? t("food.claimed_on", {
                      fulfilledAt: dayjs(fulfilledAt).format("lll"),
                    })
                  : availableForPickupAt
                  ? t("food.order_available_for_pickup", {
                      date: dayjs(availableForPickupAt).format("ll"),
                    })
                  : t("food.order_date", { date: dayjs(createdAt).format("ll") })}
              </CardText>
              <CardText>{t("food.total", { total: total })}</CardText>
            </Stack>
          </Stack>
        </DivLink>
      </CardBody>
    </Card>
  );
}
