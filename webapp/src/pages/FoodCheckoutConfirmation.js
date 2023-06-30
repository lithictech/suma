import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import { mdp, t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import React from "react";
import { Alert } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Stack from "react-bootstrap/Stack";
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
  if (loading) {
    return <PageLoader />;
  }
  const { fulfillmentOption, items, offering } = checkout;
  return (
    <>
      <div className="bg-success text-white p-3">
        <Alert.Heading>{t("food:confirmation_title")}</Alert.Heading>
        <p className="mb-0">{t("food:confirmation_subtitle")}</p>
      </div>
      <LayoutContainer top>
        <h4 className="mb-3">{t("food:checkout_items_title")}</h4>
        {items.map((p, idx) => (
          <Item key={idx} item={p} />
        ))}
        <hr />
        <h4 className="mb-3">{offering.fulfillmentConfirmation}</h4>
        <p>{fulfillmentOption.description}</p>
        <hr />
        {mdp("food:confirmation_message", { check: false })}
        <Stack className="mt-2">
          <Button variant="outline-success" href="/dashboard" as={RLink}>
            {t("common:go_home")}
          </Button>
        </Stack>
      </LayoutContainer>
    </>
  );
}

function Item({ item }) {
  const { product, quantity } = item;
  return (
    <>
      <Col xs={12} className="mb-3">
        <Stack direction="horizontal" gap={3} className="align-items-start">
          <SumaImage
            image={product.images[0]}
            alt={product.name}
            className="rounded"
            w={90}
            h={90}
          />
          <Stack>
            <p className="mb-0 lead">{product.name}</p>
            <p className="text-secondary">{t("food:quantity", { quantity: quantity })}</p>
          </Stack>
        </Stack>
      </Col>
    </>
  );
}
