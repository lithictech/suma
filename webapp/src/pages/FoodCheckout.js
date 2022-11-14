import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import Stack from "react-bootstrap/Stack";
import { Link, useLocation, useParams, useSearchParams } from "react-router-dom";

export default function FoodCheckout() {
  const { id } = useParams();
  const { state } = useLocation();
  const [searchParams] = useSearchParams();
  const {
    state: fetchedCheckout,
    loading,
    error,
    asyncFetch,
  } = useAsyncFetch(api.getCheckout, {
    default: state?.checkout,
    pickData: true,
    doNotFetchOnInit: true,
  });
  React.useEffect(() => {
    if (_.isEmpty(fetchedCheckout)) {
      asyncFetch({ id });
    }
  }, [asyncFetch, fetchedCheckout, id]);

  const [checkoutMutations, setCheckoutMutations] = React.useState({});
  const checkout = _.merge({}, fetchedCheckout, checkoutMutations);

  const [manuallySelectedInstrument, setManuallySelectedInstrument] =
    React.useState(null);
  const instrumentFromUrl = _.find(checkout.availablePaymentInstruments, {
    id: Number(searchParams.get("instrumentId")),
    paymentMethodType: searchParams.get("instrumentType"),
  });

  const chosenInstrument =
    manuallySelectedInstrument || instrumentFromUrl || checkout.chosenInstrument;

  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (loading || _.isEmpty(checkout)) {
    return <PageLoader />;
  }
  return (
    <Row>
      <CheckoutPayment
        checkout={checkout}
        selectedInstrument={chosenInstrument}
        onSelectedInstrumentChange={(pi) => setManuallySelectedInstrument(pi)}
      />
      <hr />
      <CheckoutFulfillment
        checkout={checkout}
        onCheckoutChange={(attrs) =>
          setCheckoutMutations({ ...checkoutMutations, ...attrs })
        }
      />
      <hr />
      <CheckoutItems checkout={checkout} />
      <hr />
      <OrderSummary checkout={checkout} chosenInstrument={chosenInstrument} />
    </Row>
  );
}

function CheckoutPayment({ checkout, selectedInstrument, onSelectedInstrumentChange }) {
  const addButtons = (
    <>
      <Button
        href={`/add-card?returnTo=/checkout/${checkout.id}`}
        as={RLink}
        variant="outline-success"
        size="sm"
      >
        Add debit/credit card
      </Button>
      <Button
        href={`/link-bank-account?returnTo=/checkout/${checkout.id}`}
        as={RLink}
        variant="outline-success"
        size="sm"
      >
        Link bank account
      </Button>
    </>
  );

  return (
    <Col xs={12} className="mb-3">
      <h5>How are you paying?</h5>
      {_.isEmpty(checkout.availablePaymentInstruments) && (
        <Stack gap={2}>
          <span className="small text-secondary">
            Link a payment method to pay for this order.
          </span>
          {addButtons}
        </Stack>
      )}
      {!_.isEmpty(checkout.availablePaymentInstruments) && (
        <Stack gap={2}>
          <Form>
            <Form.Group>
              {checkout.availablePaymentInstruments.map((pi) => (
                <PaymentInstrumentRadio
                  key={pi.key}
                  id={pi.key}
                  instrument={pi}
                  checked={pi.key === selectedInstrument?.key}
                  onChange={() => onSelectedInstrumentChange(pi)}
                />
              ))}
            </Form.Group>
          </Form>
          <div>Or, link a new payment method to pay for this order.</div>
          {addButtons}
        </Stack>
      )}
    </Col>
  );
}

function PaymentInstrumentRadio({ id, instrument, checked, onChange }) {
  return (
    <Form.Check
      id={id}
      type="radio"
      name="paymentOption"
      label={<PaymentLabel {...instrument} />}
      checked={checked}
      onChange={onChange}
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

function CheckoutFulfillment({ checkout, onCheckoutChange }) {
  return (
    <Col xs={12} className="mb-3">
      <h5>How do you want to get your stuff?</h5>
      <Form noValidate>
        <Form.Group>
          {checkout.availableFulfillmentOptions.map((fo) => (
            <Form.Check
              key={fo.id}
              id={fo.id}
              name={fo.description}
              type="radio"
              label={fo.description}
              checked={checkout.fulfillmentOptionId === fo.id}
              onChange={() => onCheckoutChange({ fulfillmentOptionId: fo.id })}
            />
          ))}
        </Form.Group>
      </Form>
    </Col>
  );
}

function CheckoutItems({ checkout }) {
  return (
    <Col className="mb-3">
      <h5 className="mb-3">Here&rsquo;s what you&rsquo;re getting:</h5>
      {checkout.items?.map((it, idx) => {
        return (
          <React.Fragment key={it.product.productId}>
            {idx > 0 && <hr className="mb-3 mt-0" />}
            <CheckoutItem item={it} />
          </React.Fragment>
        );
      })}
    </Col>
  );
}

function OrderSummary({ checkout, chosenInstrument }) {
  const canPlace = checkout.fulfillmentOptionId && chosenInstrument;
  const itemCount = _.sum(_.map(checkout.items, "quantity"));
  return (
    <Col xs={12} className="mb-3">
      <h5>Order summary</h5>
      <div>
        <SummaryLine label={`Items (${itemCount})`} price={checkout.undiscountedCost} />
        <SummaryLine label="Handling" price={checkout.handling} />
        <SummaryLine
          label="Total savings"
          price={checkout.savings}
          subtract
          className="text-success"
        />
        <hr className="ms-auto w-25 my-1" />
        <SummaryLine label={`Total before tax`} price={checkout.taxableCost} />
        <SummaryLine label={`Tax`} price={checkout.tax} />
        <hr className="mt-1 mb-2" />
        <SummaryLine
          label="Order total"
          price={checkout.total}
          className="text-success fw-bold fs-5"
        />
        <Button variant="success" className="d-flex ms-auto mt-2" disabled={!canPlace}>
          Place order
        </Button>
      </div>
      <p className="small text-secondary mt-2">
        By clicking &#34;place order&#34; you are agreeing to suma&#39;s{" "}
        <Link to="/TODO user agreement">Terms of Use</Link>.
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

function CheckoutItem({ item }) {
  const { product, quantity } = item;
  return (
    <>
      <Col xs={12} className="mb-3">
        <Stack direction="horizontal" gap={3} className="align-items-start">
          <SumaImage
            image={product.images[0]}
            alt={product.name}
            className="rounded"
            w={80}
            h={80}
          />
          <Stack className="justify-content-between">
            <h6 className="mb-0">{product.name}</h6>
            <div className="mb-0 text-secondary">
              <small>{t("food:from") + " " + product.vendor.name}</small>
            </div>
            <div className="mb-0 text-secondary">
              <small>Quantity: {quantity}</small>
            </div>
          </Stack>
          <p className="ms-auto fs-6">
            <Money className={clsx("me-2", product.isDiscounted && "text-success")}>
              {product.customerPrice}
            </Money>
            {product.isDiscounted && (
              <strike>
                <Money>{product.undiscountedPrice}</Money>
              </strike>
            )}
          </p>
        </Stack>
      </Col>
    </>
  );
}
