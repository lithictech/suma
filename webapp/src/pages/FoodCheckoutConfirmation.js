import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
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
  const { fulfillmentOption, items } = checkout;
  return (
    <>
      <div className="bg-success text-white p-3">
        <Alert.Heading>Order placed successfully!</Alert.Heading>
        <p className="mb-0">
          You will get a message soon with details about how to get your order.
        </p>
      </div>
      <LayoutContainer top>
        <h4 className="mb-3">What you&rsquo;re getting</h4>
        {items.map((p, idx) => (
          <Item key={idx} item={p} />
        ))}
        <hr />
        <h4 className="mb-3">How you&rsquo;re getting it</h4>
        <p>{fulfillmentOption.description}</p>
        <hr />
        <p>
          Respond to your confirmation message or reach out if you have any questions.
        </p>
        <Stack className="mt-2">
          <Button variant="outline-success" href="/dashboard">
            Take me home!
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
            <p className="text-secondary">Quantity: {quantity}</p>
          </Stack>
        </Stack>
      </Col>
    </>
  );
}
