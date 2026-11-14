import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import { RoutePath } from "../routing/RoutePath.ts";
import Button from "../ui/Button";
import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import CardText from "../ui/CardText";
import DivLink from "../ui/DivLink.tsx";
import Icon from "../ui/Icon.tsx";
import IndeterminateLoader from "../ui/IndeterminateLoader.tsx";
import Stack from "../ui/Stack";
import { ShoppingBagIcon } from "@heroicons/react/24/outline";
import isEmpty from "lodash/isEmpty";
import React from "react";

interface OrderListProps {
  user: CurrentMember;
  orders: SimpleOrderHistory[];
  loading: boolean;
  onNavigate: (o: SimpleOrderHistory) => void;
}

export default function OrderList({ user, orders, loading, onNavigate }: OrderListProps) {
  return loading ? (
    <IndeterminateLoader variant="plain" color="primary" />
  ) : !isEmpty(orders) ? (
    <Stack col gap={5}>
      <UnclaimedOrders user={user} />
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
    <Card>
      <CardBody>
        <Stack col gap={5}>
          {t("food.no_orders")}
          <Button to="/food">{t("food.available_offerings")}</Button>
        </Stack>
      </CardBody>
    </Card>
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

function UnclaimedOrders({ user }: { user?: CurrentMember }) {
  if (!user || user.unclaimedOrders.length === 0) {
    return null;
  }
  return (
    <Card>
      <CardBody>
        <Stack col gap={5}>
          <Stack row gap={5}>
            <Icon
              icon={ShoppingBagIcon}
              color="primary"
              invert
              className="p-3"
              size={32}
            />
            <h3>{user.unclaimedOrders.length} ready to claim</h3>
          </Stack>
          {user.unclaimedOrders.map(({ id, offeringName, orderedAt, summary }) => (
            <DivLink
              key={id}
              to={`/order/${id}` as RoutePath}
              className="bgcolor-secondary-soft p-4 border-radius-sm"
            >
              <h5 className="font-size-body-md mb-1">{offeringName}</h5>
              <p className="font-size-body-md color-text-muted">
                Ordered {dayjs(orderedAt).format("ll")} &bull;
                {summary}
              </p>
            </DivLink>
          ))}
        </Stack>
      </CardBody>
    </Card>
  );

  //   <Alert
  //     color="success"
  //     text={t("dashboard.claim_orders")}
  //     icon={ShoppingBagIcon}
  //     to="/unclaimed-orders"
  //   />
  // );
}
