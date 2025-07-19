import api from "../api";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import ReactCreditCards from "../components/ReactCreditCards";
import config from "../config";
import { t } from "../localization";
import elementDimensions from "../modules/elementDimensions";
import keepDigits from "../modules/keepDigits";
import { extractErrorCode } from "../state/useError";
import useScreenLoader from "../state/useScreenLoader";
import get from "lodash/get";
import Payment from "payment";
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
  const [number, setNumber] = React.useState(config.devCardDetails.number || "");
  const [expiry, setExpiry] = React.useState(config.devCardDetails.expiry || "");
  const [cvc, setCvc] = React.useState(config.devCardDetails.cvc || "");
  const [focus, setFocus] = React.useState("");

  const runSetter = React.useCallback(
    (name, set, value) => {
      clearErrors(name);
      setValue(name, value);
      set(value);
    },
    [clearErrors, setValue]
  );

  const handleSubmitInner = React.useCallback(() => {
    const exp = keepDigits(expiry);
    screenLoader.turnOn();
    setError("");
    const form = new FormData();
    form.set("card[name]", name);
    form.set("card[number]", number);
    form.set("card[exp_month]", exp[0] + exp[1]);
    form.set("card[exp_year]", exp[2] + exp[3]);
    form.set("card[cvc]", cvc);
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
        if (!get(e, "response.data.error.type")) {
          setError(extractErrorCode(e));
          return;
        }
        const errkey = `errors.${e.response.data.error.type}.${e.response.data.error.code}`;
        let localized = t(errkey);
        if (localized === errkey) {
          localized = e.response.data.error.message;
        }
        setError(<span>{localized}</span>);
      });
  }, [cvc, expiry, name, number, onSuccess, screenLoader, setError]);

  const handleFocus = (e) => {
    setFocus(e.target.name);
    setTimeout(() => setRerender(rerender + 1), 0);
  };
  const handleBlur = () => setFocus("");

  const handleExpiryChange = (e) => {
    let { name, value } = e.target;
    value = paymentLibSafeExpiry(value);
    runSetter(name, setExpiry, value);
    const digits = keepDigits(value).length;
    if (digits === 4) {
      cvcRef.current.focus();
    }
  };

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
            as={Col}
            required
            type="text"
            name="name"
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
            inputRef={(r) => r && Payment.formatCardNumber(r)}
            as={Col}
            required
            type="text"
            pattern="\d*"
            inputMode="numeric"
            name="number"
            autoComplete="cc-number"
            autoCorrect="off"
            spellCheck="false"
            label={t("forms.card_number")}
            value={number}
            errors={errors}
            registerOptions={{ validate: Payment.fns.validateCardNumber }}
            errorKeys={{ validate: "forms.invalid_card_number" }}
            register={register}
            onChange={(e) => runSetter(e.target.name, setNumber, e.target.value)}
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
            // Do NOT use Payment here, it has bugs.
            as={Col}
            required
            type="text"
            pattern="\d*"
            inputMode="numeric"
            name="expiry"
            autoComplete="cc-exp"
            autoCorrect="off"
            spellCheck="false"
            label={"MM / YY"}
            value={expiry}
            errors={errors}
            register={register}
            registerOptions={{ validate: Payment.fns.validateCardExpiry }}
            errorKeys={{ validate: "forms.invalid_card_expiry" }}
            onChange={handleExpiryChange}
            onFocus={handleFocus}
            onBlur={handleBlur}
          />
          <FormControlGroup
            inputRef={(r) => {
              cvcRef.current = r;
              r && Payment.formatCardCVC(r);
            }}
            as={Col}
            required
            type="text"
            pattern="\d*"
            inputMode="numeric"
            name="cvc"
            autoComplete="cc-cvc"
            autoCorrect="off"
            spellCheck="false"
            label={"CVC"}
            value={cvc}
            errors={errors}
            register={register}
            registerOptions={{ validate: Payment.fns.validateCardCVC }}
            errorKeys={{ validate: "forms.invalid_card_cvc" }}
            onChange={(e) => runSetter(e.target.name, setCvc, e.target.value)}
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
            <ReactCreditCards
              cvc={cvc}
              expiry={reactCardSafeExpiry(expiry)}
              focused={focus}
              name={name}
              number={number}
            />
          </Col>
        </Row>
      </Form>
    </>
  );
}

function reactCardSafeExpiry(s) {
  // It doesn't work with 00 / 00, only 00/00
  const digits = keepDigits(s);
  if (digits.length < 2) {
    return digits;
  } else if (digits.length === 2) {
    return digits + "/";
  } else {
    return digits.slice(0, 2) + "/" + digits.slice(2);
  }
}

function paymentLibSafeExpiry(s) {
  const digits = keepDigits(s);
  if (digits.length < 3) {
    return digits;
  } else {
    return digits.slice(0, 2) + " / " + digits.slice(2);
  }
}
