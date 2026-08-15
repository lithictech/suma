import api from "../api";
import BackBreadcrumb from "../components/BackBreadcrumb";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageHeading from "../components/PageHeading";
import PageLoader from "../components/PageLoader";
import SeeAlsoAlert from "../components/SeeAlsoAlert";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useUser from "../state/useUser";
import Button from "../ui/Button";
import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import CardLink from "../ui/CardLink";
import CardText from "../ui/CardText";
import Stack from "../ui/Stack";
import find from "lodash/find";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useNavigate } from "react-router-dom";

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
    navigate(`/order/${order.id}`, { state: { order: detailed } });
  }
  return (
    <>
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
      <LayoutContainer top={user.unclaimedOrdersCount === 0} gutters>
        <BackBreadcrumb back="/food" />
        <PageHeading>{t("food.order_history_title")}</PageHeading>
      </LayoutContainer>
      <LayoutContainer gutters>
        {loading ? (
          <PageLoader />
        ) : !isEmpty(orderHistory?.items) ? (
          <Stack gap={3}>
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
      </LayoutContainer>
    </>
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
        <Stack direction="horizontal" gap={3}>
          <SumaImage
            image={image}
            width={80}
            height={80}
            className="border rounded"
            variant="dark"
          />
          <div>
            <CardLink href={`/order/${id}`} className="h5" onClick={onNavigate}>
              {t("food.order_serial", { serial: serial })}
            </CardLink>
            <CardText className="text-secondary mt-1">
              {fulfilledAt
                ? t("food.claimed_on", {
                    fulfilledAt: dayjs(fulfilledAt).format("lll"),
                  })
                : availableForPickupAt
                ? t("food.order_available_for_pickup", {
                    date: dayjs(availableForPickupAt).format("ll"),
                  })
                : t("food.order_date", { date: dayjs(createdAt).format("ll") })}
              <br />
              {t("food.total", { total: total })}
            </CardText>
          </div>
        </Stack>
      </CardBody>
    </Card>
  );
}
