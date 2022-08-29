import api from "../api";
import CurrencyNumpad from "../components/CurrencyNumpad";
import ErrorScreen from "../components/ErrorScreen";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import ScreenLoader from "../components/ScreenLoader";
import { t } from "../localization";
import idempotency from "../modules/idempotency";
import { Logger } from "../shared/logger";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import _ from "lodash";
import React from "react";
import Form from "react-bootstrap/Form";
import { useNavigate, useSearchParams } from "react-router-dom";

const logger = new Logger("addfunds");

export default function FundingAddFunds() {
  const [error, setError] = useError();
  const { user, handleUpdateCurrentMember } = useUser();
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const [amountCents, setAmountCents] = React.useState(0);
  const [selectedCurrencyCode] = React.useState("");

  const {
    state: currenciesResp,
    loading: currenciesLoading,
    error: currenciesError,
  } = useAsyncFetch(api.getSupportedCurrencies, {
    default: { items: [] },
    pickData: true,
  });
  const instrument =
    _.find(user.usablePaymentInstruments, {
      id: Number(params.get("id")),
      paymentMethodType: params.get("paymentMethodType"),
    }) || {};
  const screenLoader = useScreenLoader();
  // Once we have multiple currencies, we'll need to figure out how to select one
  const validCurrencies = _.filter(currenciesResp.items, (c) =>
    _.includes(c.paymentMethodTypes, instrument.paymentMethodType)
  );
  const selectedCurrency =
    _.find(validCurrencies, { code: selectedCurrencyCode }) ||
    _.first(validCurrencies) ||
    {};

  const handleFormSubmit = (e) => {
    e.preventDefault();
    if (amountCents < selectedCurrency?.fundingMinimumCents) {
      setError(
        <span>
          {t("forms:invalid_min_amount", {
            constraint: {
              cents: selectedCurrency?.fundingMinimumCents,
              currency: selectedCurrency?.code,
            },
          })}
        </span>
      );
      return;
    }
    screenLoader.turnOn();
    idempotency.runAsync("add-funds", () =>
      api
        .createFundingPayment({
          amount: {
            cents: amountCents,
            currency: selectedCurrency.code,
          },
          paymentMethodId: instrument.id,
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
      .context({ instruments: user.usablePaymentInstruments })
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

  return (
    <>
      <h2 className="page-header">{t("payments:add_funds")}</h2>
      <p>{t("payments:add_funds_intro")}</p>
      <Form noValidate onSubmit={handleFormSubmit}>
        <div className="d-flex justify-content-center mb-3">
          <div style={{ maxWidth: 400, flex: 1 }}>
            <CurrencyNumpad
              currency={selectedCurrency}
              layout={{ default: ["1 2 3", "4 5 6", "7 8 9", " 0 "] }}
              whole
              cents={amountCents}
              onCentsChange={handleChange}
            />
          </div>
        </div>
        <p>{t("payments:payment_submission_statement")}</p>
        <FormError error={error} end />
        <FormButtons
          variant="outline-success"
          back
          primaryProps={{
            disabled: !amountCents,
            style: { minWidth: 120 },
            children: t("forms:add_funds"),
          }}
        />
      </Form>
    </>
  );
}
