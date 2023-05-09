import { t } from "../localization";
import { useUser } from "../state/useUser";
import { LayoutContainer } from "../state/withLayout";
import React from "react";
import Button from "react-bootstrap/Button";

export default function UnclaimedOrdersWidget() {
  const { user } = useUser();
  if (user.unclaimedOrdersCount === 0) {
    return null;
  }
  return (
    <LayoutContainer top gutters>
      <Button
        variant="outline-dark"
        size="sm"
        className="w-100 d-flex justify-content-between"
        href="/order-history?unclaimed=true"
      >
        {t("food:unclaimed_orders", { unclaimedOrdersCount: user.unclaimedOrdersCount })}
        <span className="ms-auto">
          <i className="bi-arrow-right"></i>
        </span>
      </Button>
    </LayoutContainer>
  );
}
