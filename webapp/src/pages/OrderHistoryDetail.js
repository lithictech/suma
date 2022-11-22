import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { md, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import React from "react";
import { Stack } from "react-bootstrap";
import Card from "react-bootstrap/Card";
import { useLocation, useParams } from "react-router-dom";

export default function OrderHistoryDetail() {
  const { id } = useParams();
  const location = useLocation();
  const getOrderDetails = React.useCallback(() => api.getOrderDetails({ id }), [id]);
  const { state, loading, error } = useAsyncFetch(getOrderDetails, {
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
        <LinearBreadcrumbs back="/order-history" />
      </LayoutContainer>
      <LayoutContainer gutters>
        <Stack gap={3}>
          <div>
            <h2 className="mb-1">{t("food:order_serial", { serial: state.serial })}</h2>
            {dayjs(state.createdAt).format("lll")}
          </div>
          <p className="mb-0">
            {t("food:labels:price", { price: state.customerCost })}
            <Money as="del" className="text-secondary ms-2">
              {state.undiscountedCost}
            </Money>
            <br />
            {t("food:labels:fees_and_taxes", { fees: state.handling, taxes: state.tax })}
            <br />
            {t("food:labels:total", { total: state.total })}
            {state.fundingTransactions.map(({ label, amount }) => (
              <React.Fragment key={label}>
                <br />
                {label}: <Money>{amount}</Money>
              </React.Fragment>
            ))}
            <br />
            <span>{state.fulfillmentOption.description}</span>
          </p>
          <SumaImage
            image={state.image}
            w={350}
            height={150}
            className="rounded responsive-wide-image"
          />
          <hr className="my-0" />
          <Stack>
            <Card.Text className="h4">
              {t("food:labels:items_count", { itemCount: state.items.length })}
            </Card.Text>
            {state.items.map(({ name, description, customerPrice, quantity }, i) => (
              <Stack
                direction="horizontal"
                key={i}
                className="justify-content-between align-items-start"
              >
                <div>
                  <div className="lead">{name}</div>
                  <div className="text-secondary">{description}</div>
                </div>
                <span className="ms-2 lead text-end">
                  {md("food:price_times_quantity_md", { price: customerPrice, quantity })}
                </span>
              </Stack>
            ))}
          </Stack>
        </Stack>
      </LayoutContainer>
    </>
  );
}
