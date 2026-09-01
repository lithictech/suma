import { r, t } from "../localization";
import { AppError, extractAppErrorAny } from "../modules/feedback.ts";
import keepDigits from "../modules/keepDigits.ts";
import { scaleMoney } from "../modules/money.ts";
import Payment, { PaymentCardField, PaymentCardParams } from "../modules/payment.ts";
import { RoutePath, untypedRoutePath } from "../routing/RoutePath.ts";
import { HandleUpdateCurrentMember } from "../state/UserProvider.tsx";
import useScreenLoader from "../state/useScreenLoader.ts";
import useStripeErrorMessage from "../state/useStripeErrorMessage.ts";
import useValidationError from "../state/useValidationError.ts";
import Alert from "../ui/Alert.tsx";
import Button from "../ui/Button.tsx";
import Form from "../ui/Form.tsx";
import FormSubmit from "../ui/FormSubmit.tsx";
import Stack from "../ui/Stack.tsx";
import TextInput from "../ui/TextInput.tsx";
import CreditCardPreview from "./CreditCardPreview.tsx";
import GoHome from "./GoHome.tsx";
import { AxiosResponse } from "axios";
import get from "lodash/get";
import React from "react";
import { useForm } from "react-hook-form";

interface AddCreditCardProps {
  user: CurrentMember;
  handleUpdateCurrentMember: HandleUpdateCurrentMember;
  onSubmit: (
    params: PaymentCardParams
  ) => Promise<AxiosResponse<MutationPaymentInstrument>>;
  navigate: (p: RoutePath) => void;
  /** Where to return to after adding the card. Shows on the success screen. */
  returnTo?: string;
  /** Where to return to after adding the card. Navigates immediately. */
  returnToImmediate?: string;
  /** For testing only. */
  stubData?: { name: string; number: string; expiry: string; cvc: string };
  /** For testing only. */
  stubCreatedInstrument?: CreatedInstrument;
}

interface CreatedInstrument {
  id: number;
  paymentMethodType: string;
}

export default function AddCreditCard({
  user,
  handleUpdateCurrentMember,
  returnTo,
  returnToImmediate,
  navigate,
  onSubmit,
  stubData,
  stubCreatedInstrument,
}: AddCreditCardProps) {
  const {
    register,
    handleSubmit,
    watch,
    setFocus,
    setValue,
    getValues,
    formState: { errors },
  } = useForm<PaymentCardParams>({
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
  const [createdCard, setCreatedCard] = React.useState<CreatedInstrument | null>(
    stubCreatedInstrument || null
  );
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
    screenLoader.turnOn();
    setError(null);
    onSubmit(v)
      .then((r) => {
        handleUpdateCurrentMember(r);
        if (returnToImmediate) {
          navigate(makeReturnUrl(returnToImmediate, r.data));
          return;
        }
        setCreatedCard(r.data);
        screenLoader.turnOff();
      })
      .catch((e: any) => {
        screenLoader.turnOff();
        const errMsg = localizeStripeError(get(e, "response.data"));
        const feedback = errMsg ? new AppError("", {}, errMsg) : extractAppErrorAny(e);
        setError(feedback);
      });
  }, [
    getValues,
    screenLoader,
    onSubmit,
    handleUpdateCurrentMember,
    returnToImmediate,
    navigate,
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

  if (createdCard) {
    return <Success instrument={createdCard} returnTo={returnTo} />;
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
          <Stack row gap={3}>
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
          <Stack center col className="my-3">
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

function Success({
  instrument,
  returnTo,
}: {
  instrument: CreatedInstrument;
  returnTo?: string;
}) {
  return (
    <Stack col gap={4}>
      <h2>{t("payments.added_card")}</h2>
      {t("payments.added_card_successful")}
      {returnTo ? (
        <div className="button-stack mt-4">
          <Button to={makeReturnUrl(returnTo, instrument)} variant="outline">
            {t("forms.continue")}
          </Button>
        </div>
      ) : (
        <GoHome />
      )}
    </Stack>
  );
}

function makeReturnUrl(returnTo: string, instr: CreatedInstrument) {
  return untypedRoutePath(
    `${returnTo}?instrumentId=${instr.id}&instrumentType=${instr.paymentMethodType}`
  );
}
