import ErrorScreen from "../components/ErrorScreen";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
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
import { Link, useSearchParams } from "react-router-dom";

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
    </>
  );
}

function CheckoutPayment() {
  const [params] = useSearchParams();
  const [isChangingPayment, setIsChangingPayment] = React.useState(false);
  const { user, userLoading } = useUser();
  const chosenPaymentInstrument = _.find(user.usablePaymentInstruments, {
    id: Number(params.get("instrumentId")),
    paymentMethodType: params.get("instrumentType"),
  });
  // TODO: fix
  const [payment, setPayment] = React.useState(
    chosenPaymentInstrument || user.usablePaymentInstruments[0]
  );
  if (userLoading) {
    return <PageLoader relative />;
  }
  return (
    <Col xs={12} className="mb-4">
      <h5>Payment method</h5>
      {!_.isEmpty(payment) && !isChangingPayment ? (
        <>
          <PaymentLabel {...payment} />
          <Link to="#" onClick={() => setIsChangingPayment(true)}>
            Change payment option
          </Link>
        </>
      ) : (
        <Stack gap={2}>
          <span className="small text-secondary">
            Choose from the payment options, add a card or link a bank account.
          </span>
          <Form>
            <Form.Group>
              {_.filter(user.usablePaymentInstruments, { canUseForFunding: true }).map(
                (p) => (
                  <PaymentInstrumentRadio
                    key={p.id + p.paymentMethodType}
                    payment={p}
                    currentPayment={payment}
                    onPaymentChange={setPayment}
                  />
                )
              )}
            </Form.Group>
          </Form>
          <Button
            href="/add-card?returnTo=/food-checkout"
            as={RLink}
            variant="outline-success"
            size="sm"
          >
            Add debit/credit card
          </Button>
          <Button
            href="/link-bank-account?returnTo=/food-checkout"
            as={RLink}
            variant="outline-success"
            size="sm"
          >
            Link bank account
          </Button>
          <Button
            variant="link text-capitalize"
            size="sm"
            onClick={() => setIsChangingPayment(false)}
          >
            Save changes
          </Button>
        </Stack>
      )}
    </Col>
  );
}

function PaymentInstrumentRadio({ payment, currentPayment, onPaymentChange }) {
  const radioId = payment.id + payment.last4;
  return (
    <Form.Check
      id={radioId}
      type="radio"
      name="paymentOption"
      label={<PaymentLabel {...payment} />}
      defaultChecked={radioId === currentPayment.id + currentPayment.last4}
      onChange={() => onPaymentChange(payment)}
    />
  );
}

function PaymentLabel({ institution, last4, name }) {
  name = institution.name.toLowerCase() === "unknown" ? name : institution.name;
  return (
    <>
      {!_.isEmpty(institution.logo) && (
        <img
          className="me-2"
          style={{ width: "28px" }}
          src={`data://${institution.logo}`}
          alt={institution.name}
        />
      )}
      <span className="me-1">{name}</span>
      <span className="text-secondary me-2">ending in {last4}</span>
    </>
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
          className="text-success fw-bold fs-5"
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
