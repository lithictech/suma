import api from "../api.ts";
import { t } from "../localization";
// import elementDimensions from "../modules/elementDimensions.ts";
import { AppError, extractAppErrorAny } from "../modules/feedback.ts";
import keepDigits from "../modules/keepDigits.ts";
import { scaleMoney } from "../modules/money.ts";
import Payment from "../modules/payment.ts";
import useScreenLoader from "../state/useScreenLoader.ts";
import useStripeErrorMessage from "../state/useStripeErrorMessage.ts";
import Alert from "../ui/Alert.tsx";
import Form from "../ui/Form.tsx";
import FormSubmit from "../ui/FormSubmit.tsx";
import Stack from "../ui/Stack.tsx";
import TextInput from "../ui/TextInput.tsx";
import CreditCardPreview from "./CreditCardPreview.tsx";
import get from "lodash/get";
import React from "react";
import { useForm } from "react-hook-form";

type StripeToken = string;

interface AddCreditCardProps {
  user: CurrentMember;
  onSuccess: (data: StripeToken) => void;
  stripePublicKey: string;
  stubData?: { name: string; number: string; expiry: string; cvc: string };
}

export default function AddCreditCard({
  user,
  onSuccess,
  stripePublicKey,
  stubData,
}: AddCreditCardProps) {
  const {
    register,
    handleSubmit,
    // clearErrors,
    setValue,
    getValues,
    formState: { errors },
  } = useForm<{ name: string; number: string; expiry: string; cvc: string }>({
    mode: "all",
    defaultValues: {
      name: stubData?.name || "",
      number: stubData?.number || "",
      expiry: stubData?.expiry || "",
      cvc: stubData?.cvc || "",
    },
  });

  const [error, setError] = React.useState<AppError | null>();

  const screenLoader = useScreenLoader();
  // const numberRowRef = React.useRef<HTMLDivElement>(null);
  // const expiryRowRef = React.useRef<HTMLDivElement>(null);
  // const cvcRef = React.useRef<HTMLInputElement>(null);
  // const errorRowRef = React.useRef<HTMLElement>(null);
  // const buttonRowRef = React.useRef<HTMLDivElement>(null);
  // const cardRowRef = React.useRef<HTMLDivElement>(null);
  // const [rerender, setRerender] = React.useState(1);

  const cardInfo = React.useMemo(() => {
    const v = getValues();
    return new Payment.CardInfo(v.number, v.expiry, v.cvc);
  }, [getValues]);

  const [focus, setFocus] = React.useState("");

  const { localizeStripeError } = useStripeErrorMessage();

  // const runSetter = React.useCallback(
  //   (name: string, set: (value: string) => void, value: string) => {
  //     setFeedback(null);
  //     clearErrors(name);
  //     setValue(name, value);
  //     set(value);
  //   },
  //   [clearErrors, setError, setValue]
  // );

  const handleSubmitInner = React.useCallback(() => {
    const v = getValues();
    const exp = keepDigits(v.expiry);
    screenLoader.turnOn();
    setError(null);
    const form = new FormData();
    form.set("card[name]", v.name);
    form.set("card[number]", v.number);
    form.set("card[exp_month]", exp[0] + exp[1]);
    form.set("card[exp_year]", exp[2] + exp[3]);
    form.set("card[cvc]", v.cvc);
    const body = new URLSearchParams(
      form as unknown as Record<string, string>
    ).toString();
    api.axios
      .post("https://api.stripe.com/v1/tokens", body, {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          Authorization: `Bearer ${stripePublicKey}`,
        },
      })
      .then((r) => onSuccess(r.data as string))
      .catch((e: any) => {
        screenLoader.turnOff();
        const errMsg = localizeStripeError(get(e, "response.data"));
        const feedback = errMsg ? new AppError("", {}, errMsg) : extractAppErrorAny(e);
        setError(feedback);
        (document.activeElement as HTMLElement | null)?.blur();
      });
  }, [
    getValues,
    screenLoader,
    setError,
    stripePublicKey,
    onSuccess,
    localizeStripeError,
  ]);

  const handleFocus = (e: React.FocusEvent<HTMLInputElement>) => {
    setFocus(e.target.name);
    // setTimeout(() => setRerender(rerender + 1), 0);
  };
  const handleBlur = () => setFocus("");

  function handleCardNumberChange(e: React.ChangeEvent<HTMLInputElement>) {
    const value = Payment.handleDigitInputWithFormatting(e, { pci: cardInfo });
    setValue("number", value);
  }

  function handleCardExpiryChange(e: React.ChangeEvent<HTMLInputElement>) {
    const value = Payment.handleDigitInputWithFormatting(e, { pci: cardInfo });
    setValue("expiry", value);
    // if (value.length === 4) {
    //   cvcRef.current?.focus();
    // }
  }

  function handleCardCvcChange(e: React.ChangeEvent<HTMLInputElement>) {
    const value = keepDigits(e.target.value);
    setValue("cvc", value);
  }

  const numberOffset = 0,
    expOffset = 0,
    // errorOffset = 0,
    // buttonsOffset = 0,
    cardOffset = 0;
  if (focus) {
    // const numberDims = elementDimensions(numberRowRef.current);
    // const expiryDims = elementDimensions(expiryRowRef.current);
    // const errorDims = elementDimensions(errorRowRef.current);
    // const buttonDims = elementDimensions(buttonRowRef.current);
    // const cardDims = elementDimensions(cardRowRef.current);
    // if (focus === "name") {
    //   numberOffset = cardDims.h;
    //   expOffset = cardDims.h;
    //   errorOffset = cardDims.h;
    //   buttonsOffset = cardDims.h;
    //   cardOffset =
    //     -buttonDims.h - errorDims.h - expiryDims.h - numberDims.h + cardDims.my;
    // } else if (focus === "number") {
    //   expOffset = cardDims.h;
    //   errorOffset = cardDims.h;
    //   buttonsOffset = cardDims.h;
    //   cardOffset = -buttonDims.h - errorDims.h - expiryDims.h + cardDims.my;
    // } else if (focus === "expiry" || focus === "cvc") {
    //   errorOffset = cardDims.h;
    //   buttonsOffset = cardDims.h;
    //   cardOffset = -buttonDims.h - errorDims.h + cardDims.my;
    // }
  }
  return (
    <>
      <Form noValidate onSubmit={handleSubmit(handleSubmitInner)}>
        <Stack col gap={2}>
          <TextInput
            required
            type="text"
            autoComplete="name"
            autoCorrect="off"
            spellCheck="false"
            label={t("forms.name")}
            {...register("name", { required: "Name is required" })}
            error={errors.name?.message}
            onFocus={handleFocus}
            onBlur={handleBlur}
          />
          <Stack
            row
            // ref={numberRowRef}
            className="mb-3 cc-animate"
            style={{ transform: `translateY(${numberOffset}px)` }}
          >
            <TextInput
              required
              type="text"
              pattern="\d*"
              inputMode="numeric"
              autoComplete="cc-number"
              autoCorrect="off"
              spellCheck="false"
              label={t("forms.card_number")}
              // value={Payment.formatCardNumber(cardInfo, { editing: true })}
              {...register("number", {
                validate: (number) =>
                  !Payment.invalidCardNumberReason(cardInfo.change({ number })),
              })}
              // errorKeys={{ validate: "forms.invalid_card_number" }}
              // register={register}
              onChange={handleCardNumberChange}
              onFocus={handleFocus}
              onBlur={handleBlur}
            />
          </Stack>
          <Stack
            row
            // ref={expiryRowRef}
            className="mb-3 cc-animate"
            style={{ transform: `translateY(${expOffset}px)` }}
          >
            <TextInput
              required
              type="text"
              pattern="\d*"
              inputMode="numeric"
              autoComplete="cc-exp"
              autoCorrect="off"
              spellCheck="false"
              label={"MM / YY"}
              // value={Payment.formatCardExpiry(cardInfo, { editing: true })}
              {...register("expiry", {
                validate: {
                  format: (expiry) =>
                    Payment.invalidCardExpiryReason(cardInfo.change({ expiry })) !==
                    Payment.Invalid.FORMAT,
                  expired: (expiry) =>
                    Payment.invalidCardExpiryReason(cardInfo.change({ expiry })) !==
                    Payment.Invalid.EXPIRED,
                },
              })}
              // errorKeys={{
              //   format: "forms.invalid_card_expiry",
              //   expired: "forms.invalid_card_expired",
              onChange={handleCardExpiryChange}
              onFocus={handleFocus}
              onBlur={handleBlur}
            />
            <TextInput
              required
              type="text"
              pattern="\d*"
              inputMode="numeric"
              autoComplete="cc-cvc"
              autoCorrect="off"
              spellCheck="false"
              label="CVC"
              {...register("cvc", {
                validate: (cvc) =>
                  !Payment.invalidCardCvcReason(cardInfo.change({ cvc })),
              })}
              // value={Payment.formatCardCvc(cardInfo, { editing: true })}
              // errorKeys={{ validate: "forms.invalid_card_cvc" }}
              onChange={handleCardCvcChange}
              onFocus={handleFocus}
              onBlur={handleBlur}
            />
          </Stack>
          {/*<FormFeedback*/}
          {/*  ref={errorRowRef}*/}
          {/*  error={error}*/}
          {/*  className="cc-animate"*/}
          {/*  style={{ transform: `translateY(${errorOffset}px)` }}*/}
          {/*/>*/}
          <NegativeBalanceAddInstrumentNotice user={user} />
          <FormSubmit label={t("forms.submit")} back feedback={error} />
          {/*<FormButtons*/}
          {/*  ref={buttonRowRef}*/}
          {/*  className="mb-3 cc-animate"*/}
          {/*  style={{ transform: `translateY(${buttonsOffset}px)` }}*/}
          {/*  variant="outline"*/}
          {/*  back*/}
          {/*  primaryProps={{*/}
          {/*    children: t("forms.continue"),*/}
          {/*  }}*/}
          {/*/>*/}
          <Stack
            row
            // ref={cardRowRef}
            className="mb-3 cc-animate"
            style={{ transform: `translateY(${cardOffset}px)` }}
          >
            <CreditCardPreview
              cardInfo={cardInfo}
              focused={focus}
              name={getValues().name}
            />
          </Stack>
        </Stack>
      </Form>
    </>
  );
}

function NegativeBalanceAddInstrumentNotice({ user }: { user: CurrentMember }) {
  if (!user.chargeableCashBalance) {
    return null;
  }

  const balance = scaleMoney(user!.chargeableCashBalance, -1);

  return (
    <Alert
      variant="warning"
      text={t("payments.negative_balance_add_instrument_notice", {
        amount: balance,
      })}
    />
  );
}
