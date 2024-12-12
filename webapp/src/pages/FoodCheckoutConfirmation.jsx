import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useUser from "../state/useUser";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";
import Stack from "react-bootstrap/Stack";
import { useLocation, useParams } from "react-router-dom";

export default function FoodCheckoutConfirmation() {
  const { user } = useUser();
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
    return <PageLoader buffered />;
  }
  const { fulfillmentOption, items, offering } = checkout;
  return (
    <>
      <div className="bg-success text-white p-4">
        <Alert.Heading>{t("food:confirmation_title")}</Alert.Heading>
        <p className="mb-0">{t("food:confirmation_subtitle")}</p>
      </div>
      <LayoutContainer gutters top>
        <h4 className="mb-3">{t("food:confirmation_my_order")}</h4>
        {items.map((p, idx) => (
          <Item key={idx} item={p} />
        ))}
        {user.unclaimedOrdersCount !== 0 && (
          <div className="button-stack my-4">
            <Button variant="success" href="/unclaimed-orders" as={RLink}>
              {t("food:unclaimed_order_history_title")}
            </Button>
          </div>
        )}
        {offering.fulfillmentInstructions && (
          <p className="lead">{offering.fulfillmentInstructions}</p>
        )}
      </LayoutContainer>
      <hr className="my-4" />
      {fulfillmentOption && (
        <>
          <LayoutContainer gutters>
            <h4>{offering.fulfillmentConfirmation}</h4>
            <p>{fulfillmentOption.description}</p>
          </LayoutContainer>
          <hr className="my-4" />
        </>
      )}
      <LayoutContainer gutters>
        <h4>{t("food:confirmation_transportation_title")}</h4>
        <p className="mb-0">{t("food:confirmation_transportation_subtitle")}</p>
        <div className="button-stack mt-3 mb-4">
          <Button href="/mobility" as={RLink}>
            <i className="bi bi-scooter me-2"></i>
            {t("food:mobility_options")}
          </Button>
        </div>
      </LayoutContainer>
      <hr className="my-4" />
      <LayoutContainer gutters>{t("food:confirmation_help")}</LayoutContainer>
    </>
  );
}

function Item({ item }) {
  const { product, quantity } = item;
  return (
    <Stack direction="horizontal" gap={3} className="mb-3 align-items-start">
      <SumaImage
        image={product.images[0]}
        className="rounded"
        width={90}
        height={90}
        variant="dark"
      />
      <Stack>
        <p className="mb-0 lead">{product.name}</p>
        <p className="text-secondary mb-0">
          {t("food:quantity", { quantity: quantity })}
        </p>
      </Stack>
    </Stack>
  );
}
