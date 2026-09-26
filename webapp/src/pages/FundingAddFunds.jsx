import api from "../api";
import CurrencyNumpad from "../components/CurrencyNumpad";
import ErrorScreen from "../components/ErrorScreen";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import PageHeading from "../components/PageHeading.jsx";
import ScreenLoader from "../components/ScreenLoader";
import { t } from "../localization";
import idempotency from "../modules/idempotency";
import { Logger } from "../shared/logger";
import { formatMoney } from "../shared/money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, useError } from "../state/useError";
import useScreenLoader from "../state/useScreenLoader";
import useUser from "../state/useUser";
import filter from "lodash/filter";
import find from "lodash/find";
import first from "lodash/first";
import includes from "lodash/includes";
import React from "react";
import Form from "react-bootstrap/Form";
import Modal from "react-bootstrap/Modal";
import { useNavigate, useSearchParams } from "react-router-dom";

const logger = new Logger("addfunds");

export default function FundingAddFunds() {
  const [error, setError] = useError();
  const { user, handleUpdateCurrentMember } = useUser();
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const [amountCents, setAmountCents] = React.useState(0);
  const [selectedCurrencyCode] = React.useState("");
  const showConfirm = useToggle(false);

  const {
    state: currenciesResp,
    loading: currenciesLoading,
    error: currenciesError,
  } = useAsyncFetch(api.getSupportedCurrencies, {
    default: { items: [] },
    pickData: true,
  });
  const instrument =
    find(user.paymentInstruments, {
      id: Number(params.get("id")),
      paymentMethodType: params.get("paymentMethodType"),
    }) || {};
  const screenLoader = useScreenLoader();
  // Once we have multiple currencies, we'll need to figure out how to select one
  const validCurrencies = filter(currenciesResp.items, (c) =>
    includes(c.paymentMethodTypes, instrument.paymentMethodType)
  );
  const selectedCurrency =
    find(validCurrencies, { code: selectedCurrencyCode }) || first(validCurrencies);

  const handleFormSubmit = (e) => {
    e.preventDefault();
    if (amountCents < selectedCurrency?.fundingMinimumCents) {
      setError(
        <span>
          {t("forms.invalid_min_amount", {
            constraint: {
              cents: selectedCurrency?.fundingMinimumCents,
              currency: selectedCurrency?.code,
            },
          })}
        </span>
      );
      return;
    }
    if (amountCents > selectedCurrency?.fundingMaximumCents) {
      setError(
        <span>
          {t("forms.invalid_max_amount", {
            constraint: {
              cents: selectedCurrency?.fundingMaximumCents,
              currency: selectedCurrency?.code,
            },
          })}
        </span>
      );
      return;
    }
    // Money moves here, so ask for an explicit confirmation first (3.3.4).
    showConfirm.turnOn();
  };

  const submitPayment = (e) => {
    e.preventDefault();
    showConfirm.turnOff();
    screenLoader.turnOn();
    idempotency.runAsync("add-funds", () =>
      api
        .createFundingPayment({
          amount: {
            cents: amountCents,
            currency: selectedCurrency.code,
          },
          paymentInstrumentId: instrument.id,
          paymentMethodType: instrument.paymentMethodType,
        })
        .tap(handleUpdateCurrentMember)
        .then(() => navigate(`/dashboard`, { replace: true }))
        .catch((e) => {
          setError(extractErrorCode(e));
          screenLoader.turnOff();
        })
    );
  };

  if (currenciesLoading) {
    return <ScreenLoader show />;
  }
  if (currenciesError) {
    return <ErrorScreen />;
  }
  if (!instrument.id) {
    logger
      .context({ instruments: user.paymentInstruments })
      .error("instrument_not_found");
    return <ErrorScreen />;
  }
  if (!selectedCurrency) {
    logger.context({ currencies: currenciesResp.items }).error("currency_not_found");
    return <ErrorScreen />;
  }

  function handleChange(v) {
    setAmountCents(v);
    setError(null);
  }

  const amount = { cents: amountCents, currency: selectedCurrency.code };
  const addAmountLabel = t("forms.add_amount", { amount: formatMoney(amount) });

  return (
    <>
      <PageHeading>{t("payments.add_funds")}</PageHeading>
      <p>{t("payments.add_funds_intro")}</p>
      <Form noValidate onSubmit={handleFormSubmit}>
        <div className="d-flex justify-content-center mb-3">
          <div style={{ maxWidth: 400, flex: 1 }}>
            <CurrencyNumpad
              currency={selectedCurrency}
              whole
              cents={amountCents}
              onCentsChange={handleChange}
            />
          </div>
        </div>
        <p>
          {t(`payments.payment_submission_statement_${instrument.paymentMethodType}`)}
        </p>
        <FormError error={error} end />
        <FormButtons
          variant="outline-success"
          back
          primaryProps={{
            disabled: !amountCents,
            style: { minWidth: 120 },
            children: amountCents ? addAmountLabel : t("forms.add_funds"),
          }}
        />
      </Form>
      <Modal show={showConfirm.isOn} onHide={showConfirm.turnOff} centered>
        <Modal.Header closeButton closeLabel={t("common.close")}>
          <Modal.Title as="h5">{t("payments.confirm_add_funds_title")}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            {t("payments.confirm_add_funds_body", {
              amount,
              instrument: instrument.name,
            })}
          </p>
          <FormButtons
            variant="success"
            primaryProps={{
              children: addAmountLabel,
              onClick: submitPayment,
            }}
            secondaryProps={{
              children: t("common.cancel"),
              onClick: showConfirm.turnOff,
            }}
          />
        </Modal.Body>
      </Modal>
    </>
  );
}
