import { r, t } from "../../localization";
import { dayjs } from "../../modules/dayConfig";
import {
  AppError,
  extractAppErrorAny,
  success,
  Success,
} from "../../modules/feedback.ts";
import { maskPhoneNumber } from "../../modules/maskPhoneNumber";
import { SetCurrentMember } from "../../state/UserProvider.tsx";
import useLoginRedirectLink from "../../state/useLoginRedirectLink";
import Breadcrumb from "../../ui/Breadcrumb.tsx";
import Button from "../../ui/Button";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Form from "../../ui/Form";
import FormFeedback from "../../ui/FormFeedback";
import Page from "../../ui/Page.tsx";
import Stack from "../../ui/Stack.tsx";
import TextHeader from "../../ui/TextHeader.tsx";
import "./OneTimePassword.css";
import { AxiosRequestConfig, AxiosResponse } from "axios";
import React from "react";
import { useNavigate, useLocation } from "react-router-dom";

export interface OneTimePasswordApiCalls {
  authVerify: (
    data: { phone: string; token: string },
    config?: AxiosRequestConfig
  ) => Promise<AxiosResponse<CurrentMember>>;
  authStart: (
    data: { phone: string; timezone: string },
    config?: AxiosRequestConfig
  ) => Promise<AxiosResponse<AuthFlowMember>>;
}

export interface OneTimePasswordProps {
  apiCalls: OneTimePasswordApiCalls;
  setUser: SetCurrentMember;
}

const OneTimePassword = ({ apiCalls, setUser }: OneTimePasswordProps) => {
  const navigate = useNavigate();
  const [otpChars, setOtpChars] = React.useState<string[]>(
    new Array(OTP_LENGTH).fill("")
  );
  const [error, setError] = React.useState<AppError | null>();
  const [message, setMessage] = React.useState<Success | null>(null);
  const { state } = useLocation();
  const submitRef = React.useRef<HTMLButtonElement | null>(null);
  const phoneNumber: string = state ? state.phoneNumber : undefined;
  const { redirectLink, clearRedirectLink } = useLoginRedirectLink();

  React.useEffect(() => {
    if (!phoneNumber) {
      navigate("/start", { replace: true });
    }
  }, [navigate, phoneNumber]);

  const handleOtpChange = (event: React.FormEvent<HTMLInputElement>, index = 0) => {
    const target = event.target as HTMLInputElement;
    const { value } = target;

    const onlyDigits = /^\d+$/.test(value);
    if (!onlyDigits) {
      // Reset any non-digits to previous value
      setOtpChars(setCharAt(otpChars, otpChars[index], index));
      return;
    }

    // IOS keyboard paste does not call the onPaste event, instead it calls onChange.
    // when the value equals the OTP length, we handle it
    if (value.length === OTP_LENGTH) {
      setOtpChars(value.split(""));
      submitRef.current!.disabled = false;
      submitRef.current!.focus();
      return;
    }

    // The number we just typed is to the left of the cursor location.
    const newlyTypedChar = value[(target.selectionStart || 0) - 1];
    const newOtp = setCharAt(otpChars, newlyTypedChar, index);
    setOtpChars(newOtp);

    submitRef.current!.disabled = !otpValid(newOtp);
    if (target.nextSibling) {
      // Focus next input if there is one.
      (target.nextSibling as HTMLElement).focus();
    } else if (submitRef.current) {
      // Focus submit if we're at the last input (will only focus if it's not disabled)
      submitRef.current.focus();
    }
  };

  const handleOtpKeyDown = (
    event: React.KeyboardEvent<HTMLInputElement>,
    index: number
  ) => {
    const { key, target } = event;
    if (key === "Backspace" || key === "Delete") {
      event.preventDefault();
      submitRef.current!.disabled = true;
      if (key === "Backspace" && (target as HTMLInputElement).previousSibling) {
        ((target as HTMLInputElement).previousSibling as HTMLElement).focus();
      }
      setOtpChars(setCharAt(otpChars, "", index));
    }
  };

  const handleOtpPaste = (event: React.ClipboardEvent<HTMLInputElement>) => {
    if (!event?.clipboardData) {
      return;
    }
    const digits = event.clipboardData
      .getData("text")
      .split("")
      .filter((ch) => /^\d$/.test(ch));
    if (digits.length !== OTP_LENGTH) {
      return;
    }
    // We know we have the right number of digits, so are valid.
    setOtpChars(digits);
    submitRef.current!.disabled = false;
    submitRef.current!.focus();
  };

  const handleOtpSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    submitRef.current!.disabled = true;
    setError(null);
    apiCalls
      .authVerify({ phone: phoneNumber, token: otpChars.join("") })
      .then((r) => {
        setUser(r.data);
        if (r.data.onboarded && redirectLink) {
          navigate(redirectLink);
        } else if (r.data.onboarded) {
          navigate("/dashboard");
        } else {
          navigate("/onboarding");
        }
        clearRedirectLink();
      })
      .catch((err) => {
        setOtpChars(new Array(6).fill(""));
        setMessage(null);
        setError(extractAppErrorAny(err));
        // Should happen due to OTP focus but let's make sure.
        submitRef.current!.disabled = false;
        const firstOtpField = document.getElementById("otpContainer")!
          .firstChild as HTMLElement;
        firstOtpField.focus();
      });
  };

  const handleResend = (e: React.MouseEvent) => {
    e.preventDefault();
    setOtpChars(new Array(6).fill(""));
    setError(null);
    setMessage(success(r("otp.code_resent", { phone: maskPhoneNumber(phoneNumber) })));
    const firstOtpField = document.getElementById("otpContainer")!
      .firstChild as HTMLElement;
    firstOtpField.focus();
    apiCalls
      .authStart({
        phone: phoneNumber,
        timezone: dayjs.tz.guess(),
      })
      .catch((err) => {
        setMessage(null);
        setError(extractAppErrorAny(err));
      });
  };

  const handleSubmitRef = React.useCallback((r: HTMLButtonElement | null) => {
    // On mount of the submit button, set it disabled.
    // It's a lot easier to manage focus and disabled manually, since they are dependent;
    // disabled is easy to drive via view state, but focus is not. So do both imperatively.
    // NOTE: the focus does not always work reliably due to timing issues...
    if (r) {
      r.disabled = true;
    }
    submitRef.current = r;
  }, []);

  return (
    <Page>
      <Breadcrumb to="/start" />
      <TextHeader
        title={t("otp.verify_code")}
        subtitle={
          <>
            {t("otp.enter_code_sent_to")} {maskPhoneNumber(phoneNumber)}
          </>
        }
      />
      <Form noValidate onSubmit={handleOtpSubmit} gap={3}>
        <fieldset id="otpContainer" className="otp-container">
          {otpChars.map((data, index) => (
            <input
              className="otp-field"
              type="text"
              name="otp"
              // Must use the OTP length here, so any input can capture the full paste.
              maxLength={OTP_LENGTH}
              inputMode="numeric"
              key={index}
              value={data}
              placeholder="&middot;"
              onInput={(e) => handleOtpChange(e, index)}
              onKeyDown={(e) => handleOtpKeyDown(e, index)}
              onPaste={handleOtpPaste}
              onFocus={(e) => e.target.select()}
              autoFocus={index === 0}
              aria-label={r("otp.enter_code_v2", {
                index: index + 1,
                total: OTP_LENGTH,
              })}
              autoComplete="one-time-code"
            />
          ))}
        </fieldset>
        <FormFeedback feedback={error || message} className="mt-2" />
        <Stack gap={4} className="color-text-muted font-size-body-sm" wrap center>
          {t("otp.did_not_receive")}
          <Button size="sm" variant="text" inline onClick={handleResend}>
            {t("otp.send_new_code")}
          </Button>
        </Stack>
        <ButtonGroup col bottom>
          <ContinueButton ref={handleSubmitRef}>{t("otp.verify")}</ContinueButton>
        </ButtonGroup>
      </Form>
    </Page>
  );
};

export default OneTimePassword;

const OTP_LENGTH = 6;

function otpValid(chars: string[]) {
  return chars.every(Boolean);
}

function setCharAt(chars: string[], newValue: string, index: number) {
  return [...chars.map((num, idx) => (idx === index ? newValue : num))];
}
