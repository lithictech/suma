import ErrorScreen from "../components/ErrorScreen";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { mdp, t } from "../localization";
import Money from "../shared/react/Money";
import useToggle from "../shared/react/useToggle";
import { useOffering } from "../state/useOffering";
import { useUser } from "../state/useUser";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Link } from "react-router-dom";

export default function FoodCheckout() {
  const {
    cart: { items },
    error,
    loading,
  } = useOffering();
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
      <LayoutContainer gutters>
        {!loading && (
          <>
            {_.isEmpty(items) && mdp("food:no_cart_items")}
            {/* TODO: return message and button if there aren't any items*/}
            {!_.isEmpty(items) && (
              <Row>
                <CheckoutPayment />
                <CheckoutFulfillment />
                <Col className="mb-4">
                  <h5 className="mb-3">Review items</h5>
                  {items?.map((p) => (
                    <Product key={p.productId} {...p} />
                  ))}
                </Col>
                <OrderSummary items={items} {...temporaryOrderSummaryObj} />
                {/* TODO: Enable button when member selects valid payment and fulfillment options */}
              </Row>
            )}
          </>
        )}
      </LayoutContainer>
    </>
  );
}

function CheckoutPayment() {
  const { user, userLoading } = useUser();
  if (userLoading) {
    return <PageLoader relative />;
  }
  // TODO: fix
  const payment = user.usablePaymentInstruments[0];

  const handlePaymentOptions = () => {
    // TODO: Open modal popup to change payment options?
  };
  return (
    <Col xs={12} className="mb-4">
      <h5>Payment method</h5>
      {payment ? (
        <>
          <img
            className="me-2"
            style={{ width: "28px" }}
            src={`data://${payment.institution.logo}`}
            alt={payment.institution.name}
          />
          <span className="text-secondary me-2">
            {payment.institution.name} ending in {payment.last4}
          </span>
          <Link to="#" onClick={handlePaymentOptions}>
            Change payment option
          </Link>
        </>
      ) : (
        <Button variant="success" size="sm">
          Add payment option
        </Button>
      )}
    </Col>
  );
}

function CheckoutFulfillment() {
  return (
    <Col xs={12} className="mb-4">
      <h5>Pickup options</h5>
      <Form noValidate>
        <Form.Group>
          <Form.Check
            id="sharedinsMarket"
            name="fullfillment"
            type="radio"
            label="Pick up at Sharedins Market"
          />
          <Form.Check
            id="hacienda"
            name="fullfillment"
            type="radio"
            label="Pick up at Hacienda CDC"
          />
        </Form.Group>
      </Form>
    </Col>
  );
}

function OrderSummary({
  items,
  itemsPrice,
  handlingPrice,
  savingsAmount,
  grossPrice,
  estimatedTaxAmount,
  totalOrderPrice,
}) {
  const orderButtonDisabled = useToggle(true);
  return (
    <Col xs={12} className="mb-4">
      <h5>Order summary</h5>
      <div>
        <SummaryLine label={`Items (${items.length})`} price={itemsPrice} />
        <SummaryLine label="Handling" price={handlingPrice} />
        <SummaryLine
          label="Total savings"
          price={savingsAmount}
          subtract
          className="text-success"
        />
        <hr className="ms-auto w-25 my-1" />
        <SummaryLine label="Total before tax" price={grossPrice} />
        <SummaryLine label="Estimated tax" price={estimatedTaxAmount} />
        <hr />
        <SummaryLine
          label="Order total"
          price={totalOrderPrice}
          className="text-success fw-bold"
        />
        <Button
          variant="success"
          className="d-flex ms-auto mt-2"
          disabled={orderButtonDisabled}
        >
          Place order
        </Button>
      </div>
      <p className="small text-secondary">
        By clicking &#34;place order&#34; you are agreeing to suma&#39;s{" "}
        <Link to="/privacy-policy">privacy policy</Link>.
      </p>
    </Col>
  );
}

function SummaryLine({ label, price, subtract, className }) {
  return (
    <p className={clsx("d-flex justify-content-between mb-0", className)}>
      <span>{label}:</span>
      <span>
        {subtract && "-"}
        <Money>{price}</Money>
      </span>
    </p>
  );
}

function Product({
  productId,
  name,
  isDiscounted,
  customerPrice,
  undiscountedPrice,
  // offeringId,
  // vendor,
  // image,
}) {
  // TODO: return item image, vendor variables from backend
  const temporaryImageObj = {
    caption: "",
    url: "http://localhost:22001/api/v1/images/im_9vygrwvyy9ygnllql0i5wqhhz",
  };
  const temporaryVendor = { id: 2, name: "Sheradin's Market" };
  return (
    <>
      <Col xs={12} className="mb-3">
        <Stack direction="horizontal" gap={3} className="align-items-start">
          <SumaImage
            image={temporaryImageObj}
            alt={name}
            className="w-100flex-shrink-0"
            w={80}
            h={80}
          />
          <div>
            <h6 className="mb-0">{name}</h6>
            <p className="mb-1 text-secondary">
              <small>{t("food:from") + " " + temporaryVendor.name}</small>
            </p>
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
  itemsPrice: {
    cents: 5990,
    currency: "USD",
  },
  handlingPrice: {
    cents: 300,
    currency: "USD",
  },
  savingsAmount: {
    cents: 1390,
    currency: "USD",
  },
  grossPrice: {
    cents: 4900,
    currency: "USD",
  },
  estimatedTaxAmount: {
    cents: 0,
    currency: "USD",
  },
  totalOrderPrice: {
    cents: 4900,
    currency: "USD",
  },
};
