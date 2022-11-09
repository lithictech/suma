import ErrorScreen from "../components/ErrorScreen";
import FoodCartWidget from "../components/FoodCartWidget";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import { mdp, t } from "../localization";
import Money from "../shared/react/Money";
import { useOffering } from "../state/useOffering";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Link } from "react-router-dom";

export default function FoodCart() {
  const { cart, error, loading } = useOffering();
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
  const { items } = cart;
  return (
    <>
      <LayoutContainer>
        {!loading && (
          <>
            {_.isEmpty(items) && mdp("food:no_cart_items")}
            {!_.isEmpty(items) && (
              <Row>
                <Stack direction="horizontal" gap={3} className="align-items-start">
                  <h4>Shopping Cart</h4>
                  <Link to="/food-checkout" className="ms-auto">
                    Checkout {t("common:next_sym")}
                  </Link>
                </Stack>
                <hr />
                {items.map((p) => (
                  <Product key={p.productId} item={p} />
                ))}
                <Container className="d-flex align-items-end flex-column fs-6">
                  <p>
                    Subtotal ({items.length} items):{" "}
                    <b className="ms-2">
                      <Money>{temporaryOrderSummaryObj.subtotalPrice}</Money>
                    </b>
                  </p>
                  <Button as={RLink} href="/food-checkout" variant="success">
                    Continue to Checkout
                  </Button>
                </Container>
              </Row>
            )}
          </>
        )}
      </LayoutContainer>
    </>
  );
}

function Product({ item }) {
  const {
    productId,
    name,
    isDiscounted,
    customerPrice,
    undiscountedPrice,
    // offeringId,
    // vendor,
    // image,
  } = item;
  // TODO: return item image, vendor and offeringId variables from backend
  const temporaryImageObj = {
    caption: "",
    url: "http://localhost:22001/api/v1/images/im_9vygrwvyy9ygnllql0i5wqhhz",
  };
  const temporaryVendor = { id: 2, name: "Sheradin's Market" };
  const offeringId = 1;
  return (
    <>
      <Col xs={12} className="mb-3">
        <Stack direction="horizontal" gap={3} className="align-items-start">
          <Link to={`/product/${offeringId}-${productId}`} className="flex-shrink-0">
            <SumaImage
              image={temporaryImageObj}
              alt={name}
              className="w-100"
              w={100}
              h={100}
            />
          </Link>
          <div>
            <Link to={`/product/${offeringId}-${productId}`}>
              <h6 className="mb-0">{name}</h6>
            </Link>
            <p className="mb-1 text-secondary">
              <small>{t("food:from") + " " + temporaryVendor.name}</small>
            </p>
            <FoodCartWidget product={item} />
          </div>
          <p className="ms-auto fs-6">
            <Money className={clsx("me-2", isDiscounted && "text-success")}>
              {customerPrice}
            </Money>
            {isDiscounted && (
              <strike>
                <Money>{undiscountedPrice}</Money>
              </strike>
            )}
          </p>
        </Stack>
      </Col>
      <hr className="mb-3 mt-0" />
    </>
  );
}

// TODO: Remove
const temporaryOrderSummaryObj = {
  subtotalPrice: {
    cents: 4600,
    currency: "USD",
  },
};
