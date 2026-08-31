import api from "../api.ts";
import { r, t } from "../localization";
// import elementDimensions from "../modules/elementDimensions.ts";
import { AppError, extractAppErrorAny } from "../modules/feedback.ts";
import keepDigits from "../modules/keepDigits.ts";
import { scaleMoney } from "../modules/money.ts";
import Payment, { PaymentCardField } from "../modules/payment.ts";
import useScreenLoader from "../state/useScreenLoader.ts";
import useStripeErrorMessage from "../state/useStripeErrorMessage.ts";
import useValidationError from "../state/useValidationError.ts";
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
    watch,
    setFocus,
    setValue,
    getValues,
    formState: { errors },
  } = useForm<{ name: string; number: string; expiry: string; cvc: string }>({
    mode: "all",
    reValidateMode: "onBlur",
    defaultValues: {
      name: stubData?.name || "",
      number: stubData?.number || "",
      expiry: stubData?.expiry || "",
      cvc: stubData?.cvc || "",
    },
  });
  const values = watch();
  const [error, setError] = React.useState<AppError | null>();
  const screenLoader = useScreenLoader();
  const cardInfo = React.useMemo(() => {
    return new Payment.CardInfo(values);
  }, [values]);

  const [focused, setFocused] = React.useState<PaymentCardField | null>();

  const numberValidation = {
    validate: (number: string) =>
      !Payment.invalidCardNumberReason(cardInfo.change({ number })),
  };
  const numberError = useValidationError("number", errors, numberValidation, {
    validate: "forms.invalid_card_number",
  });

  const expiryValidation = {
    validate: {
      format: (expiry: string) =>
        Payment.invalidCardExpiryReason(cardInfo.change({ expiry })) !==
        Payment.Invalid.FORMAT,
      expired: (expiry: string) =>
        Payment.invalidCardExpiryReason(cardInfo.change({ expiry })) !==
        Payment.Invalid.EXPIRED,
    },
  };
  const expiryError = useValidationError("expiry", errors, expiryValidation, {
    format: "forms.invalid_card_expiry",
    expired: "forms.invalid_card_expired",
  });

  const cvcValidation = {
    validate: (cvc: string) => !Payment.invalidCardCvcReason(cardInfo.change({ cvc })),
  };
  const cvcError = useValidationError("cvc", errors, cvcValidation, {
    validate: "forms.invalid_card_cvc",
  });

  const { localizeStripeError } = useStripeErrorMessage();

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
    setFocused(e.target.name as PaymentCardField);
  };
  const handleBlur = () => setFocused(null);

  function handleCardNumberChange(e: React.ChangeEvent<HTMLInputElement>) {
    const value = Payment.handleDigitInputWithFormatting(e, {
      pci: cardInfo,
      field: "number",
    });
    setValue("number", value, { shouldValidate: true });
  }

  function handleCardExpiryChange(e: React.ChangeEvent<HTMLInputElement>) {
    const value = Payment.handleDigitInputWithFormatting(e, {
      pci: cardInfo,
      field: "expiry",
    });
    setValue("expiry", value, { shouldValidate: true });
    if (value.length === 4) {
      setFocus("cvc");
    }
  }

  function handleCardCvcChange(e: React.ChangeEvent<HTMLInputElement>) {
    const value = keepDigits(e.target.value);
    setValue("cvc", value, { shouldValidate: true });
  }

  return (
    <>
      <Form noValidate onSubmit={handleSubmit(handleSubmitInner)}>
        <Stack col gap={2} className="cc-animate">
          <TextInput
            required
            type="text"
            autoComplete="name"
            autoCorrect="off"
            spellCheck="false"
            label={t("forms.name")}
            {...register("name", { required: r("errors.required") })}
            error={errors.name?.message}
            onFocus={handleFocus}
            onBlur={handleBlur}
          />
          <TextInput
            required
            type="text"
            pattern="\d*"
            inputMode="numeric"
            autoComplete="cc-number"
            autoCorrect="off"
            spellCheck="false"
            label={t("forms.card_number")}
            {...register("number", numberValidation)}
            value={Payment.formatCardNumber(cardInfo, { editing: true })}
            error={numberError}
            onChange={handleCardNumberChange}
            onFocus={handleFocus}
            onBlur={handleBlur}
          />
          <Stack row className="mb-3 cc-animate gap-3">
            <TextInput
              required
              type="text"
              pattern="\d*"
              inputMode="numeric"
              autoComplete="cc-exp"
              autoCorrect="off"
              spellCheck="false"
              label={"MM / YY"}
              className="w-50"
              {...register("expiry", expiryValidation)}
              value={Payment.formatCardExpiry(cardInfo, { editing: true })}
              error={expiryError}
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
              className="w-50"
              {...register("cvc", cvcValidation)}
              value={Payment.formatCardCvc(cardInfo, { editing: true })}
              error={cvcError}
              onChange={handleCardCvcChange}
              onFocus={handleFocus}
              onBlur={handleBlur}
            />
          </Stack>
          <Stack center col>
            <CreditCardPreview cardInfo={cardInfo} focused={focused} name={values.name} />
          </Stack>
          <NegativeBalanceAddInstrumentNotice user={user} />
          <FormSubmit label={t("forms.submit")} back feedback={error} />
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
