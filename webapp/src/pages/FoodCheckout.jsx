import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import ExternalLink from "../components/ExternalLink";
import FoodPrice from "../components/FoodPrice";
import FormButtons from "../components/FormButtons";
import LayoutContainer from "../components/LayoutContainer";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import { md, t } from "../localization";
import { anyMoney } from "../shared/money";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useBackendGlobals from "../state/useBackendGlobals";
import useErrorToast from "../state/useErrorToast";
import useOffering from "../state/useOffering";
import useScreenLoader from "../state/useScreenLoader";
import useUser from "../state/useUser";
import clsx from "clsx";
import find from "lodash/find";
import isEmpty from "lodash/isEmpty";
import map from "lodash/map";
import merge from "lodash/merge";
import sum from "lodash/sum";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Stack from "react-bootstrap/Stack";
import {
  Link,
  useLocation,
  useNavigate,
  useParams,
  useSearchParams,
} from "react-router-dom";

export default function FoodCheckout() {
  const { id } = useParams();
  const { handleUpdateCurrentMember } = useUser();
  const { showErrorToast } = useErrorToast();
  const location = useLocation();
  const [searchParams] = useSearchParams();
  const screenLoader = useScreenLoader();
  const navigate = useNavigate();
  const { reset: resetOffering } = useOffering();
  const getCheckout = React.useCallback(() => api.getCheckout({ id }), [id]);
  const {
    state: fetchedCheckout,
    loading,
    error,
  } = useAsyncFetch(getCheckout, {
    default: {},
    pickData: true,
    pullFromState: "checkout",
    location,
  });

  const [checkoutMutations, setCheckoutMutations] = React.useState({});
  const checkout = merge({}, fetchedCheckout, checkoutMutations);

  const [manuallySelectedInstrument, setManuallySelectedInstrument] =
    React.useState(null);
  const instrumentFromUrl = find(checkout.availablePaymentInstruments, {
    id: Number(searchParams.get("instrumentId")),
    paymentMethodType: searchParams.get("instrumentType"),
  });

  const chosenInstrument =
    manuallySelectedInstrument || instrumentFromUrl || checkout.paymentInstrument;

  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (loading || isEmpty(checkout)) {
    return <PageLoader buffered />;
  }
  function handleSubmit(e) {
    e.preventDefault();
    screenLoader.turnOn();
    api
      .completeCheckout({
        ...checkout,
        paymentInstrument: chosenInstrument,
        chargeAmountCents: checkout.chargeableTotal.cents,
      })
      .tap(handleUpdateCurrentMember)
      .then(api.pickData)
      .then((d) => {
        resetOffering();
        navigate(`/checkout/${id}/confirmation`, { state: { checkout: d } });
      })
      .catch((e) => {
        screenLoader.turnOff();
        showErrorToast(e, { extract: true });
      });
  }

  return (
    <>
      <LayoutContainer gutters>
        <LinearBreadcrumbs back={`/cart/${checkout.offering.id}`} />
      </LayoutContainer>
      {checkout.requiresPaymentInstrument && (
        <>
          <LayoutContainer gutters className="mb-4">
            <CheckoutPayment
              checkout={checkout}
              selectedInstrument={chosenInstrument}
              onSelectedInstrumentChange={(pi) => setManuallySelectedInstrument(pi)}
              onCheckoutChange={(attrs) =>
                setCheckoutMutations({ ...checkoutMutations, ...attrs })
              }
            />
          </LayoutContainer>
          <hr />
        </>
      )}
      <LayoutContainer gutters className="mb-4 mt-4">
        <CheckoutFulfillment
          checkout={checkout}
          onCheckoutChange={(attrs) =>
            setCheckoutMutations({ ...checkoutMutations, ...attrs })
          }
        />
      </LayoutContainer>
      <hr />
      <LayoutContainer gutters className="mb-4 mt-4">
        <CheckoutItems checkout={checkout} />
      </LayoutContainer>
      <hr />
      <LayoutContainer gutters className="mb-4 mt-4">
        <OrderSummary
          checkout={checkout}
          chosenInstrument={chosenInstrument}
          onSubmit={handleSubmit}
        />
      </LayoutContainer>
    </>
  );
}

function CheckoutPayment({
  checkout,
  selectedInstrument,
  onSelectedInstrumentChange,
  onCheckoutChange,
}) {
  const { isPaymentMethodSupported } = useBackendGlobals();
  const addPaymentLinks = (
    <>
      {isPaymentMethodSupported("card") && (
        <Link to={`/add-card?returnToImmediate=/checkout/${checkout.id}`}>
          <i className="bi bi-credit-card me-2" />
          {t("food:add_card")}
        </Link>
      )}
      {isPaymentMethodSupported("bank_account") && (
        <Link to={`/link-bank-account?returnTo=/checkout/${checkout.id}`}>
          <i className="bi bi-bank2 me-2" />
          {t("payments:link_bank_account")}
        </Link>
      )}
    </>
  );
  return (
    <Col xs={12}>
      <h5>{t("food:payment_title")}</h5>
      {isEmpty(checkout.availablePaymentInstruments) && (
        <Stack gap={2}>
          <span className="small text-secondary">{t("food:link_new_payment")}</span>
          {addPaymentLinks}
        </Stack>
      )}
      {!isEmpty(checkout.availablePaymentInstruments) && (
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
          <Form>
            <Form.Group>
              <Form.Check
                id="savePayment"
                name="savePayment"
                label={t("food:save_payment")}
                checked={checkout.savePaymentInstrument}
                onChange={(e) =>
                  onCheckoutChange({ savePaymentInstrument: e.target.checked })
                }
              ></Form.Check>
            </Form.Group>
          </Form>
          <div>{t("food:link_new_payment", { context: "or" })}</div>
          {addPaymentLinks}
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
      {!isEmpty(institution.logoSrc) && (
        <img
          className="me-2"
          style={{ width: "28px" }}
          src={`${institution.logoSrc}`}
          alt={institution.name}
        />
      )}
      <span className="me-1">{name}</span>
      <span className="text-secondary me-2">{t("food:ending_in", { last4: last4 })}</span>
    </>
  );
}

function CheckoutFulfillment({ checkout, onCheckoutChange }) {
  return (
    <Col xs={12}>
      <h5>{checkout.offering.fulfillmentPrompt}</h5>
      <Form noValidate>
        <Form.Group>
          {checkout.availableFulfillmentOptions.map((fo) => (
            <Form.Check
              key={fo.id}
              id={fo.id}
              name={fo.description}
              type="radio"
              label={
                <>
                  {fo.description}
                  {fo.address?.oneLineAddress && (
                    <ExternalLink
                      href={`https://www.google.com/maps/place/${fo.address.oneLineAddress}`}
                      className="ms-1 nowrap"
                    >
                      <i className="bi bi-geo-alt-fill me-1"></i>
                      {t("food:address")}
                    </ExternalLink>
                  )}
                </>
              }
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
    <Col>
      <h5>{t("food:checkout_items_title")}</h5>
      {checkout.items?.map((it, idx) => {
        return (
          <React.Fragment key={it.product.productId}>
            {idx > 0 && <hr className="my-3" />}
            <CheckoutItem item={it} />
          </React.Fragment>
        );
      })}
      <RLink to={`/cart/${checkout.offering.id}`}>
        <i className="bi bi-pencil-fill me-2" />
        {t("food:edit_quantities")}
      </RLink>
    </Col>
  );
}

function OrderSummary({ checkout, chosenInstrument, onSubmit }) {
  const itemCount = sum(map(checkout.items, "quantity"));
  const canPlace =
    checkout.fulfillmentOptionId &&
    (chosenInstrument || !checkout.requiresPaymentInstrument);
  // We only handle this reason explicitly; other reasons, assume we can still submit,
  // and if there's an error we'll deal with it.
  const showSubmit = checkout.checkoutProhibitedReason !== "charging_prohibited";

  return (
    <Col xs={12}>
      <h5>{t("food:order_summary_title")}</h5>
      <div>
        <SummaryLine
          label={t("food:labels:items_count", { itemCount: itemCount })}
          price={checkout.undiscountedCost}
        />
        <SummaryLine label="Handling" price={checkout.handling} />
        {anyMoney(checkout.savings) && (
          <SummaryLine
            label={t("food:labels:total_savings")}
            price={checkout.savings}
            subtract
            className="text-success"
          />
        )}
        <hr className="ms-auto w-25 my-1" />
        <SummaryLine
          label={t("food:labels:total_before_tax")}
          price={checkout.taxableCost}
        />
        <SummaryLine label={t("food:labels:tax")} price={checkout.tax} />
        {checkout.existingFundsAvailable.map(({ amount, name }) => (
          <SummaryLine key={name} label={name} price={amount} subtract credit />
        ))}
        <hr className="mt-1 mb-2" />

        {checkout.requiresPaymentInstrument ? (
          <>
            <SummaryLine
              label={t("food:labels:chargeable_total")}
              price={checkout.chargeableTotal}
              className="text-success fw-bold fs-5"
            />
            {chosenInstrument && (
              <p className="small text-secondary mb-1">
                {t("food:charge_to", { instrumentName: chosenInstrument.name })}.
              </p>
            )}
          </>
        ) : (
          <>
            <SummaryLine
              label={t("food:labels:chargeable_total")}
              price={checkout.chargeableTotal}
              className="text-success"
            />
          </>
        )}
        {checkout.checkoutProhibitedReason === "charging_prohibited" && (
          <Alert variant="warning" className="mt-3">
            <p>
              <i className="bi bi-exclamation-circle me-2 fs-5 d-inline"></i>
              {t("food:insufficient_funds_alert")}
            </p>
            <p>{t("food:return_to_dashboard_alert")}</p>
            <FormButtons
              primaryProps={{
                href: "/dashboard",
                variant: "primary",
                type: "button",
                children: t("common:go_to_dashboard"),
                as: RLink,
              }}
            ></FormButtons>
          </Alert>
        )}
        {showSubmit && (
          <>
            <p className="small text-secondary mt-2">
              {md("food:terms_of_use_agreement")}
            </p>
            <FormButtons
              primaryProps={{
                onClick: onSubmit,
                disabled: !canPlace,
                type: "button",
                variant: "success",
                children: t("food:order_button"),
              }}
            ></FormButtons>
          </>
        )}
      </div>
    </Col>
  );
}

function SummaryLine({ label, price, subtract, className, credit }) {
  return (
    <p className={clsx("d-flex justify-content-between mb-0", className)}>
      <span>{label}:</span>
      <span className={clsx(credit && "text-success")}>
        {subtract && "-"}
        <Money>{price}</Money>
      </span>
    </p>
  );
}

function CheckoutItem({ item }) {
  const { product, quantity } = item;
  return (
    <Col className="mb-3">
      <Stack direction="horizontal" gap={3} className="align-items-start">
        <SumaImage
          image={product.images[0]}
          alt={product.name}
          className="rounded"
          w={80}
          h={80}
        />
        {product.outOfStock ? (
          <Stack>
            <h6 className="mb-2">{product.name}</h6>
            <p className="text-secondary mb-0">{t("food:sold_out")}</p>
          </Stack>
        ) : (
          <>
            <Stack className="justify-content-between">
              <h6 className="mb-0">{product.name}</h6>
              <p className="text-secondary mb-0">
                <small>
                  {t("food:from_vendor", { vendorName: product.vendor.name })}
                </small>
              </p>
              <div className="text-secondary mb-0 lh-1">
                <small>{t("food:quantity", { quantity: quantity })}</small>
              </div>
            </Stack>
            <div className="text-end">
              <FoodPrice
                undiscountedPrice={product.undiscountedPrice}
                isDiscounted={product.isDiscounted}
                displayableCashPrice={product.displayableCashPrice}
                direction="vertical"
              />
            </div>
          </>
        )}
      </Stack>
    </Col>
  );
}
