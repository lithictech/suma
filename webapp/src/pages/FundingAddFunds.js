import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import ScreenLoader from "../components/ScreenLoader";
import TopNav from "../components/TopNav";
import { Logger } from "../shared/logger";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import _ from "lodash";
import React, { useState } from "react";
import { InputGroup } from "react-bootstrap";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { useNavigate, useSearchParams } from "react-router-dom";

const logger = new Logger("addfunds");

export default function FundingAddFunds() {
  const [error, setError] = useError();
  const { user } = useUser();
  const [params] = useSearchParams();
  const navigate = useNavigate();
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

  const [validated, setValidated] = useState(false);

  const handleSubmit = (event) => {
    const form = event.currentTarget;
    event.preventDefault();
    event.stopPropagation();
    if (form.checkValidity() === false) {
      setValidated(true);
      return;
    }
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
        <h2>Add Funds</h2>
        <p>
          Add funds to your Suma account so you can purchase discounted goods and services
          through the app.
        </p>
        <Form noValidate validated={validated} onSubmit={handleSubmit}>
          <Row className="mb-3">
            <Form.Group as={Col}>
              <Form.Label>Amount</Form.Label>
              <InputGroup className="mb-3">
                <InputGroup.Text>{selectedCurrency.symbol}</InputGroup.Text>
                <Form.Control
                  required
                  type="number"
                  min={fundingMinimumDollars}
                  step={
                    selectedCurrency.fundingStepCents / selectedCurrency.centsInDollar
                  }
                  value={amountDollars}
                  onChange={(e) => setAmountDollars(e.target.value)}
                />
                <Form.Control.Feedback type="invalid">
                  Please use a whole dollar amount greater than {selectedCurrency.symbol}
                  {fundingMinimumDollars}.
                </Form.Control.Feedback>
              </InputGroup>
              <Form.Text>
                Whole dollars amounts only. {selectedCurrency.symbol}
                {fundingMinimumDollars} minimum.
              </Form.Text>
            </Form.Group>
          </Row>
          <p>
            After you submit your payment, you will be able to use the money immediately.
            The withdrawal should hit your account in 2 or 3 business days.
          </p>
          <FormError error={error} />
          <FormButtons
            variant="success"
            back
            primaryProps={{
              disabled: !amountDollars,
              style: { minWidth: 120 },
              children: amountDollars
                ? `Add ${selectedCurrency.symbol}${amountDollars}`
                : "Submit",
            }}
          />
        </Form>
      </Container>
    </div>
  );
}
