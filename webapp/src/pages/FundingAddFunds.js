import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import FormControlGroup from "../components/FormControlGroup";
import ScreenLoader from "../components/ScreenLoader";
import TopNav from "../components/TopNav";
import { Logger } from "../shared/logger";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import i18next from "i18next";
import _ from "lodash";
import React from "react";
import { InputGroup } from "react-bootstrap";
import Container from "react-bootstrap/Container";
import Form from "react-bootstrap/Form";
import { useNavigate, useSearchParams } from "react-router-dom";
import { useForm } from "react-hook-form";

const logger = new Logger("addfunds");

export default function FundingAddFunds() {
  const [error, setError] = useError();
  const { user } = useUser();
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const {
    register,
    handleSubmit,
    clearErrors,
    setValue,
    formState: { errors },
  } = useForm({
    mode: "all",
  });
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
  // TODO: Once we have multiple currencies, we'll need to figure out how to select one
  const validCurrencies = _.filter(currenciesResp.items, (c) =>
    _.includes(c.paymentMethodTypes, instrument.paymentMethodType)
  );
  const [amountDollars, setAmountDollars] = React.useState("");
  const [selectedCurrencyCode] = React.useState("");
  const selectedCurrency =
    _.find(validCurrencies, { code: selectedCurrencyCode }) ||
    _.first(validCurrencies) ||
    {};

  const handleFormSubmit = () => {
    screenLoader.turnOn();
    api
      .createFundingPayment({
        amount: {
          cents: amountDollars * selectedCurrency.centsInDollar,
          currency: selectedCurrency.code,
        },
        paymentMethodId: instrument.id,
        paymentMethodType: instrument.paymentMethodType,
      })
      .then(() => navigate(`/dashboard`, { replace: true }))
      .catch((e) => {
        setError(extractErrorCode(e));
        screenLoader.turnOff();
      });
  };
  const runSetter = (name, set, value) => {
    clearErrors(name);
    setValue(name, value);
    set(value);
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

  const fundingMinimumDollars =
    selectedCurrency.fundingMinimumCents / selectedCurrency.centsInDollar;

  return (
    <div className="main-container">
      <TopNav />
      <Container>
        <h2>{i18next.t("payments:add_funds")}</h2>
        <p>{i18next.t("payments:add_funds_intro")}</p>
        <Form noValidate onSubmit={handleSubmit(handleFormSubmit)}>
          <FormControlGroup
            className="mb-3"
            name="amount"
            label={i18next.t("forms:amount")}
            type="number"
            required
            register={register}
            errors={errors}
            errorKeys={{min: 'forms:invalid_min_amount'}}
            value={amountDollars}
            min={fundingMinimumDollars}
            step={
              selectedCurrency.fundingStepCents / selectedCurrency.centsInDollar
            }
            text={i18next.t("forms:amount_caption", {
              constraint: selectedCurrency.symbol + fundingMinimumDollars,
            })}
            prepend={<InputGroup.Text>{selectedCurrency.symbol}</InputGroup.Text>}
            onChange={(e) => runSetter(e.target.name, setAmountDollars, e.target.value)}
          />
          <p>{i18next.t("payments:payment_submition_statement")}</p>
          <FormError error={error} />
          <FormButtons
            variant="success"
            back
            primaryProps={{
              disabled: !amountDollars,
              style: { minWidth: 120 },
              children: amountDollars
                ? i18next.t("forms:add_amount", {
                    amount: selectedCurrency.symbol + amountDollars,
                  })
                : i18next.t("forms:submit"),
            }}
          />
        </Form>
      </Container>
    </div>
  );
}
