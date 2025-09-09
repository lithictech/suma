import api from "../api";
import BackBreadcrumb from "../components/BackBreadcrumb";
import ErrorScreen from "../components/ErrorScreen";
import ExternalLink from "../components/ExternalLink";
import FoodPrice from "../components/FoodPrice";
import FormButtons from "../components/FormButtons";
import FormRadioInputs from "../components/FormRadioInputs";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SumaImage from "../components/SumaImage";
import { t } from "../localization";
import idempotency from "../modules/idempotency";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import { anyMoney } from "../shared/money";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useBackendGlobals from "../state/useBackendGlobals";
import useErrorToast from "../state/useErrorToast";
import useOffering from "../state/useOffering";
import useScreenLoader from "../state/useScreenLoader";
import useUser from "../state/useUser";
import useValidationError from "../state/useValidationError";
import clsx from "clsx";
import find from "lodash/find";
import isEmpty from "lodash/isEmpty";
import map from "lodash/map";
import merge from "lodash/merge";
import sum from "lodash/sum";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Form from "react-bootstrap/Form";
import Stack from "react-bootstrap/Stack";
import { useForm } from "react-hook-form";
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
  const {
    register,
    handleSubmit,
    clearErrors,
    setValue,
    formState: { errors },
  } = useForm({
    mode: "all",
  });

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

  const runSetter = React.useCallback(
    (name, set, value) => {
      clearErrors(name);
      setValue(name, value);
      set(value);
    },
    [clearErrors, setValue]
  );

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
  function handleSubmitInner() {
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
        <BackBreadcrumb back={`/cart/${checkout.offering.id}`} />
      </LayoutContainer>
      <Form noValidate onSubmit={handleSubmit(handleSubmitInner)}>
        {checkout.requiresPaymentInstrument && (
          <>
            <LayoutContainer gutters className="mb-4">
              <CheckoutPayment
                checkout={checkout}
                selectedInstrument={chosenInstrument}
                onSelectedInstrumentChange={(pi) =>
                  runSetter("paymentOption", setManuallySelectedInstrument, pi)
                }
                register={register}
                errors={errors}
              />
            </LayoutContainer>
            <hr />
          </>
        )}
        {!isEmpty(checkout.availableFulfillmentOptions) && (
          <>
            <LayoutContainer gutters className="my-4">
              <CheckoutFulfillment
                checkout={checkout}
                showErrorToast={showErrorToast}
                register={register}
                errors={errors}
                onCheckoutChange={(attrs) =>
                  runSetter("fulfillmentOption", setCheckoutMutations, {
                    ...checkoutMutations,
                    ...attrs,
                  })
                }
              />
            </LayoutContainer>
            <hr />
          </>
        )}
        <LayoutContainer gutters className="my-4">
          <CheckoutItems checkout={checkout} />
        </LayoutContainer>
        <hr />
        <LayoutContainer gutters className="my-4">
          <OrderSummary checkout={checkout} chosenInstrument={chosenInstrument} />
        </LayoutContainer>
      </Form>
    </>
  );
}

function CheckoutPayment({
  checkout,
  selectedInstrument,
  onSelectedInstrumentChange,
  register,
  errors,
}) {
  const paymentValidationInputName = "paymentInputBackupValidationError";
  const isInvalid = !!errors[paymentValidationInputName];
  const { isPaymentMethodSupported } = useBackendGlobals();
  const addPaymentLinks = (
    <>
      {isPaymentMethodSupported("card") && (
        <Link
          to={`/add-card?returnToImmediate=/checkout/${checkout.id}`}
          className={clsx(isInvalid && "link-danger")}
        >
          <i className="bi bi-credit-card me-2" />
          {t("food.add_card")}
        </Link>
      )}
      {isPaymentMethodSupported("bank_account") && (
        <Link
          to={`/link-bank-account?returnTo=/checkout/${checkout.id}`}
          className={clsx(isInvalid && "link-danger")}
        >
          <i className="bi bi-bank2 me-2" />
          {t("payments.link_bank_account")}
        </Link>
      )}
    </>
  );
  function handleChange(e) {
    const instrumentKey = e.target.value;
    const instrument = checkout.availablePaymentInstruments.find(
      (pi) => pi.key === instrumentKey
    );
    onSelectedInstrumentChange(instrument);
  }
  const inputs = checkout.availablePaymentInstruments.map((pi) => ({
    id: pi.key,
    label: <PaymentLabel {...pi} />,
  }));
  return (
    <>
      <h5>{t("food.payment_title")}</h5>
      <Stack gap={2}>
        {checkout.unavailablePaymentInstruments
          .filter((pi) => pi.status === "expired")
          .map((pi) => (
            <Stack key={pi.id} direction="horizontal" className="opacity-50">
              <PaymentLabel {...pi} />
            </Stack>
          ))}
        {isEmpty(checkout.availablePaymentInstruments) ? (
          <>
            <span className="small text-secondary">{t("food.link_new_payment")}</span>
            {addPaymentLinks}
            <PaymentsInputValidationMessage
              name={paymentValidationInputName}
              register={register}
              errors={errors}
            />
          </>
        ) : (
          <>
            <Form.Group>
              <FormRadioInputs
                inputs={inputs}
                name="paymentOption"
                selected={selectedInstrument?.key}
                register={register}
                errors={errors}
                onChange={handleChange}
                required
              />
            </Form.Group>
            <div>{t("food.link_new_payment_or")}</div>
            {addPaymentLinks}
          </>
        )}
      </Stack>
    </>
  );
}

function PaymentLabel({ institution, last4, name, status }) {
  name = institution.name.toLowerCase() === "unknown" ? name : institution.name;
  return (
    <>
      {status === "expired" && (
        <span className="text-danger me-2">{t("payments.payment_account_expired")}</span>
      )}
      {!isEmpty(institution.logoSrc) && (
        <img
          className="me-2"
          style={{ width: "28px" }}
          src={`${institution.logoSrc}`}
          alt=""
        />
      )}
      <span className="me-1">{name}</span>
      <span className="text-secondary me-2">{t("food.ending_in", { last4: last4 })}</span>
    </>
  );
}

function CheckoutFulfillment({ checkout, onCheckoutChange, register, errors }) {
  const handleCheckoutChange = (e) => {
    const id = Number(e.target.value);
    if (checkout.fulfillmentOptionId === id) {
      return;
    }
    // We save the fulfillment choice, but it is only a convenience-
    // because we also submit the option id
    // when completing the checkout, we don't need to worry about any failures or latency
    // when saving the selected option.
    onCheckoutChange({ fulfillmentOptionId: id });
    idempotency.runAsync("update-checkout-fulfillment", () =>
      api.updateCheckoutFulfillment({ checkoutId: checkout.id, optionId: id })
    );
  };
  const inputs = checkout.availableFulfillmentOptions.map((fo) => ({
    id: fo.id,
    label: <FulfillmentOptionLabel {...fo} />,
  }));
  return (
    <>
      {checkout.offering.fulfillmentPrompt && (
        <h5>{checkout.offering.fulfillmentPrompt}</h5>
      )}
      {checkout.offering.fulfillmentInstructions && (
        <p className="mb-2">{checkout.offering.fulfillmentInstructions}</p>
      )}
      <FormRadioInputs
        inputs={inputs}
        name="fulfillmentOption"
        selected={checkout.fulfillmentOptionId}
        register={register}
        errors={errors}
        onChange={(e) => handleCheckoutChange(e)}
      />
    </>
  );
}

function FulfillmentOptionLabel({ description, address }) {
  return (
    <>
      {description}
      {address?.oneLineAddress && (
        <ExternalLink
          href={`https://www.google.com/maps/place/${address.oneLineAddress}`}
          className="ms-1 nowrap"
        >
          <i className="bi bi-geo-alt-fill me-1"></i>
          {t("food.address")}
        </ExternalLink>
      )}
    </>
  );
}

function CheckoutItems({ checkout }) {
  return (
    <>
      <h5>{t("food.checkout_items_title")}</h5>
      {checkout.items?.map((it, idx) => {
        return (
          <React.Fragment key={it.product.productId}>
            {idx > 0 && <hr className="my-3" />}
            <CheckoutItem item={it} />
          </React.Fragment>
        );
      })}
      <div className="mt-3">
        <RLink to={`/cart/${checkout.offering.id}`}>
          <i className="bi bi-pencil-fill me-2" />
          {t("food.edit_quantities")}
        </RLink>
      </div>
    </>
  );
}

function OrderSummary({ checkout, chosenInstrument }) {
  const itemCount = sum(map(checkout.items, "quantity"));
  // We only handle this reason explicitly; other reasons, assume we can still submit,
  // and if there's an error we'll deal with it.
  const showSubmit = checkout.checkoutProhibitedReason !== "member_unverified";
  return (
    <>
      <h5>{t("food.order_summary_title")}</h5>
      <div>
        <SummaryLine
          label={t("food.labels.items_count", { itemCount: itemCount })}
          price={checkout.undiscountedCost}
        />
        <SummaryLine label={t("food.labels.handling")} price={checkout.handling} />
        {anyMoney(checkout.savings) && (
          <SummaryLine
            label={t("food.labels.total_savings")}
            price={checkout.savings}
            subtract
            className="text-success"
          />
        )}
        <hr className="ms-auto w-25 my-1" />
        <SummaryLine
          label={t("food.labels.total_before_tax")}
          price={checkout.taxableCost}
        />
        <SummaryLine label={t("food.labels.tax")} price={checkout.tax} />
        {checkout.existingFundsAvailable.map(({ amount, name }) => (
          <SummaryLine key={name} label={name} price={amount} subtract credit />
        ))}
        <hr className="mt-1 mb-2" />
        {checkout.requiresPaymentInstrument ? (
          <>
            <SummaryLine
              label={t("food.labels.chargeable_total")}
              price={checkout.chargeableTotal}
              className="text-success fw-bold fs-5"
            />
            {chosenInstrument && (
              <p className="small text-secondary mb-1">
                {t("food.charge_to", { instrumentName: chosenInstrument.name })}.
              </p>
            )}
          </>
        ) : (
          <SummaryLine
            label={t("food.labels.chargeable_total")}
            price={checkout.chargeableTotal}
            className="text-success"
          />
        )}
        {checkout.checkoutProhibitedReason === "member_unverified" && (
          <Alert variant="danger" className="mt-3">
            {t("errors.read_only_unverified")}
          </Alert>
        )}
        {showSubmit && (
          <>
            <p className="small text-secondary mt-2">
              {t("food.terms_of_use_agreement")}
            </p>
            <FormButtons
              primaryProps={{
                variant: "success",
                children: t("food.order_button"),
              }}
            />
          </>
        )}
      </div>
    </>
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
    <Stack direction="horizontal" gap={3} className="align-items-start">
      <SumaImage
        image={product.images[0]}
        className="rounded"
        width={80}
        height={80}
        variant="dark"
      />
      {product.outOfStock ? (
        <Stack>
          <h6 className="mb-2">{product.name}</h6>
          <p className="text-secondary mb-0">{t("food.sold_out")}</p>
        </Stack>
      ) : (
        <>
          <Stack className="justify-content-between">
            <h6 className="mb-0">{product.name}</h6>
            <p className="text-secondary mb-0">
              <small>{t("food.from_vendor", { vendorName: product.vendor.name })}</small>
            </p>
            <div className="text-secondary mb-0 lh-1">
              <small>{t("food.quantity", { quantity: quantity })}</small>
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
  );
}

/**
 * The payments component, when it's empty, shows two links.
 * If someone submits, and nothing is selected, we want to show an error,
 * just like if it was a radiobutton group with nothing selected.
 * However these are not inputs, so the validation system doesn't work.
 * We have to create a fake input (with d-none) and then show the error message.
 */
function PaymentsInputValidationMessage({ name, register, errors }) {
  const registerOptions = { required: true };
  const message = useValidationError(name, errors, registerOptions, {
    required: "forms.invalid_required",
  });
  return (
    <>
      <input {...register(name, registerOptions)} className="d-none" required />
      {message && (
        <>
          <ScrollTopOnMount />
          <Form.Control.Feedback type="invalid" className="d-block">
            {message}
          </Form.Control.Feedback>
        </>
      )}
    </>
  );
}
