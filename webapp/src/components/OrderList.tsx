import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import { RoutePath } from "../routing/RoutePath.ts";
import Button from "../ui/Button";
import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import CardText from "../ui/CardText";
import DivLink from "../ui/DivLink.tsx";
import IndeterminateLoader from "../ui/IndeterminateLoader.tsx";
import Stack from "../ui/Stack";
import isEmpty from "lodash/isEmpty";
import React from "react";

interface OrderListProps {
  orders: SimpleOrderHistory[];
  loading: boolean;
  onNavigate: (o: SimpleOrderHistory) => void;
}

export default function OrderList({ orders, loading, onNavigate }: OrderListProps) {
  return loading ? (
    <IndeterminateLoader variant="plain" />
  ) : !isEmpty(orders) ? (
    <Stack col gap={3}>
      {orders.map((o) => (
        <Order
          key={o.id}
          {...o}
          onNavigate={(e: React.MouseEvent) => {
            e.preventDefault();
            onNavigate(o);
          }}
        />
      ))}
    </Stack>
  ) : (
    <>
      {t("food.no_orders")}
      <div className="button-stack mt-2">
        <Button variant="primary" to="/food">
          {t("food.available_offerings")}
        </Button>
      </div>
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
