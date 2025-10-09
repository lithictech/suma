import api from "../api";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import config from "../config";
import { t } from "../localization";
import elementDimensions from "../modules/elementDimensions";
import keepDigits from "../modules/keepDigits";
import Payment from "../modules/payment";
import { extractErrorCode } from "../state/useError";
import useScreenLoader from "../state/useScreenLoader";
import useStripeErrorMessage from "../state/useStripeErrorMessage";
import CreditCardPreview from "./CreditCardPreview.jsx";
import get from "lodash/get";
import React from "react";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { useForm } from "react-hook-form";

export default function AddCreditCard({ onSuccess, error, setError }) {
  const {
    register,
    handleSubmit,
    clearErrors,
    setValue,
    formState: { errors },
  } = useForm({
    mode: "all",
  });

  const screenLoader = useScreenLoader();
  const numberRowRef = React.useRef(null);
  const expiryRowRef = React.useRef(null);
  const cvcRef = React.useRef(null);
  const errorRowRef = React.useRef(null);
  const buttonRowRef = React.useRef(null);
  const cardRowRef = React.useRef(null);
  const [rerender, setRerender] = React.useState(1);

  const [name, setName] = React.useState(config.devCardDetails.name || "");
  const [cardNumber, setCardNumber] = React.useState(config.devCardDetails.number || "");
  const [cardExpiry, setCardExpiry] = React.useState(config.devCardDetails.expiry || "");
  const [cardCvc, setCardCvc] = React.useState(config.devCardDetails.cvc || "");

  const cardInfo = React.useMemo(
    () => new Payment.CardInfo(cardNumber, cardExpiry, cardCvc),
    [cardNumber, cardExpiry, cardCvc]
  );

  const [focus, setFocus] = React.useState("");

  const { localizeStripeError } = useStripeErrorMessage();

  const runSetter = React.useCallback(
    (name, set, value) => {
      setError("");
      clearErrors(name);
      setValue(name, value);
      set(value);
    },
    [clearErrors, setError, setValue]
  );

  const handleSubmitInner = React.useCallback(() => {
    const exp = keepDigits(cardExpiry);
    screenLoader.turnOn();
    setError("");
    const form = new FormData();
    form.set("card[name]", name);
    form.set("card[number]", cardNumber);
    form.set("card[exp_month]", exp[0] + exp[1]);
    form.set("card[exp_year]", exp[2] + exp[3]);
    form.set("card[cvc]", cardCvc);
    const body = new URLSearchParams(form).toString();
    api.axios
      .post("https://api.stripe.com/v1/tokens", body, {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          Authorization: `Bearer ${config.stripePublicKey}`,
        },
      })
      .then((r) => onSuccess(r.data))
      .catch((e) => {
        screenLoader.turnOff();
        const errMsg =
          localizeStripeError(get(e, "response.data")) || extractErrorCode(e);
        setError(<span>{errMsg}</span>);
        document.activeElement?.blur();
      });
  }, [
    cardCvc,
    cardExpiry,
    localizeStripeError,
    name,
    cardNumber,
    onSuccess,
    screenLoader,
    setError,
  ]);

  const handleFocus = (e) => {
    setFocus(e.target.name);
    setTimeout(() => setRerender(rerender + 1), 0);
  };
  const handleBlur = () => setFocus("");

  function handleCardNumberChange(e) {
    const value = Payment.handleDigitInputWithFormatting(e, { pci: cardInfo });
    runSetter(e.target.name, setCardNumber, value);
  }

  function handleCardExpiryChange(e) {
    const value = Payment.handleDigitInputWithFormatting(e, { pci: cardInfo });
    runSetter(e.target.name, setCardExpiry, value);
    if (value.length === 4) {
      cvcRef.current.focus();
    }
  }

  function handleCardCvcChange(e) {
    let { name, value } = e.target;
    value = keepDigits(value);
    runSetter(name, setCardCvc, value);
  }

  let numberOffset = 0,
    expOffset = 0,
    errorOffset = 0,
    buttonsOffset = 0,
    cardOffset = 0;
  if (focus) {
    const numberDims = elementDimensions(numberRowRef.current);
    const expiryDims = elementDimensions(expiryRowRef.current);
    const errorDims = elementDimensions(errorRowRef.current);
    const buttonDims = elementDimensions(buttonRowRef.current);
    const cardDims = elementDimensions(cardRowRef.current);
    if (focus === "name") {
      numberOffset = cardDims.h;
      expOffset = cardDims.h;
      errorOffset = cardDims.h;
      buttonsOffset = cardDims.h;
      cardOffset =
        -buttonDims.h - errorDims.h - expiryDims.h - numberDims.h + cardDims.my;
    } else if (focus === "number") {
      expOffset = cardDims.h;
      errorOffset = cardDims.h;
      buttonsOffset = cardDims.h;
      cardOffset = -buttonDims.h - errorDims.h - expiryDims.h + cardDims.my;
    } else if (focus === "expiry" || focus === "cvc") {
      errorOffset = cardDims.h;
      buttonsOffset = cardDims.h;
      cardOffset = -buttonDims.h - errorDims.h + cardDims.my;
    }
  }
  return (
    <>
      <Form noValidate onSubmit={handleSubmit(handleSubmitInner)}>
        <Row className="mb-3">
          <FormControlGroup
            name="name"
            as={Col}
            required
            type="text"
            autoComplete="name"
            autoCorrect="off"
            spellCheck="false"
            label={t("forms.name")}
            value={name}
            errors={errors}
            register={register}
            onChange={(e) => runSetter(e.target.name, setName, e.target.value)}
            onFocus={handleFocus}
            onBlur={handleBlur}
          />
        </Row>
        <Row
          ref={numberRowRef}
          className="mb-3 cc-animate"
          style={{ transform: `translateY(${numberOffset}px)` }}
        >
          <FormControlGroup
            name="number"
            as={Col}
            required
            type="text"
            pattern="\d*"
            inputMode="numeric"
            autoComplete="cc-number"
            autoCorrect="off"
            spellCheck="false"
            label={t("forms.card_number")}
            value={Payment.formatCardNumber(cardInfo, { editing: true })}
            errors={errors}
            registerOptions={{
              validate: (number) =>
                !Payment.invalidCardNumberReason(cardInfo.change({ number })),
            }}
            errorKeys={{ validate: "forms.invalid_card_number" }}
            register={register}
            onChange={handleCardNumberChange}
            onFocus={handleFocus}
            onBlur={handleBlur}
          />
        </Row>
        <Row
          ref={expiryRowRef}
          className="mb-3 cc-animate"
          style={{ transform: `translateY(${expOffset}px)` }}
        >
          <FormControlGroup
            name="expiry"
            as={Col}
            required
            type="text"
            pattern="\d*"
            inputMode="numeric"
            autoComplete="cc-exp"
            autoCorrect="off"
            spellCheck="false"
            label={"MM / YY"}
            value={Payment.formatCardExpiry(cardInfo, { editing: true })}
            errors={errors}
            register={register}
            registerOptions={{
              validate: {
                format: (expiry) =>
                  Payment.invalidCardExpiryReason(cardInfo.change({ expiry })) !==
                  Payment.Invalid.FORMAT,
                expired: (expiry) =>
                  Payment.invalidCardExpiryReason(cardInfo.change({ expiry })) !==
                  Payment.Invalid.EXPIRED,
              },
            }}
            errorKeys={{
              format: "forms.invalid_card_expiry",
              expired: "forms.invalid_card_expired",
            }}
            onChange={handleCardExpiryChange}
            onFocus={handleFocus}
            onBlur={handleBlur}
          />
          <FormControlGroup
            inputRef={cvcRef}
            name="cvc"
            as={Col}
            required
            type="text"
            pattern="\d*"
            inputMode="numeric"
            autoComplete="cc-cvc"
            autoCorrect="off"
            spellCheck="false"
            label={"CVC"}
            value={Payment.formatCardCvc(cardInfo, { editing: true })}
            errors={errors}
            register={register}
            registerOptions={{
              validate: (cvc) => !Payment.invalidCardCvcReason(cardInfo.change({ cvc })),
            }}
            errorKeys={{ validate: "forms.invalid_card_cvc" }}
            onChange={handleCardCvcChange}
            onFocus={handleFocus}
            onBlur={handleBlur}
          />
        </Row>
        <FormError
          ref={errorRowRef}
          error={error}
          className="cc-animate"
          style={{ transform: `translateY(${errorOffset}px)` }}
        />
        <FormButtons
          ref={buttonRowRef}
          className="mb-3 cc-animate"
          style={{ transform: `translateY(${buttonsOffset}px)` }}
          variant="outline-primary"
          back
          primaryProps={{
            children: t("forms.continue"),
          }}
        />
        <Row
          ref={cardRowRef}
          className="mb-3 cc-animate"
          style={{ transform: `translateY(${cardOffset}px)` }}
        >
          <Col>
            <CreditCardPreview cardInfo={cardInfo} focused={focus} name={name} />
          </Col>
        </Row>
      </Form>
    </>
  );
}
