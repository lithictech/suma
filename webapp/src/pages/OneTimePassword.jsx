import api from "../api";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import FormSuccess from "../components/FormSuccess";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import { maskPhoneNumber } from "../modules/maskPhoneNumber";
import { extractLocalizedError, useError } from "../state/useError";
import useLoginRedirectLink from "../state/useLoginRedirectLink";
import useUser from "../state/useUser";
import React from "react";
import Button from "react-bootstrap/Button";
import Form from "react-bootstrap/Form";
import { useNavigate, useLocation } from "react-router-dom";

const OneTimePassword = () => {
  const navigate = useNavigate();
  const { setUser } = useUser();
  const [otpChars, setOtpChars] = React.useState(new Array(OTP_LENGTH).fill(""));
  const [error, setError] = useError();
  const [message, setMessage] = React.useState();
  const { state } = useLocation();
  const submitRef = React.useRef(null);
  const phoneNumber = state ? state.phoneNumber : undefined;
  const { redirectLink, clearRedirectLink } = useLoginRedirectLink();

  React.useEffect(() => {
    if (!phoneNumber) {
      navigate("/start", { replace: true });
    }
  }, [navigate, phoneNumber]);

  const handleOtpChange = (event, index = 0) => {
    const { target } = event;
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
      submitRef.current.focus();
      return;
    }

    // The number we just typed is to the left of the cursor location.
    const newlyTypedChar = value[event.target.selectionStart - 1];
    const newOtp = setCharAt(otpChars, newlyTypedChar, index);
    setOtpChars(newOtp);

    if (target.nextSibling) {
      // Focus next input if there is one.
      target.nextSibling.focus();
    } else if (otpValid(newOtp)) {
      // At the last input with a full code, so focus submit.
      submitRef.current.focus();
    } else {
      // At the last input but an earlier box is empty, so go back to it.
      focusFirstEmptyField(newOtp);
    }
  };

  const handleOtpKeyDown = (event, index) => {
    const { key, target } = event;
    if (key === "Backspace" || key === "Delete") {
      event.preventDefault();
      if (key === "Backspace" && target.previousSibling) {
        target.previousSibling.focus();
      }
      setOtpChars(setCharAt(otpChars, "", index));
    }
  };

  const handleOtpPaste = (event) => {
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
    submitRef.current.focus();
  };

  const handleOtpSubmit = (e) => {
    e.preventDefault();
    // The submit button is always enabled, so members are told what is missing
    // rather than having to work out why the button does nothing.
    if (!otpValid(otpChars)) {
      setMessage(null);
      setError("otp_incomplete");
      focusFirstEmptyField(otpChars);
      return;
    }
    // Disabled only while the request is in flight, to avoid double submits.
    submitRef.current.disabled = true;
    setError(null);
    api
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
        submitRef.current.disabled = false;
        setOtpChars(new Array(6).fill(""));
        setMessage(null);
        setError(extractLocalizedError(err));
        const firstOtpField = document.getElementById("otpContainer").firstChild;
        firstOtpField.focus();
      });
  };

  const handleResend = () => {
    setOtpChars(new Array(6).fill(""));
    setError(null);
    setMessage(["otp.code_resent", { phone: maskPhoneNumber(phoneNumber) }]);
    const firstOtpField = document.getElementById("otpContainer").firstChild;
    firstOtpField.focus();
    api
      .authStart({
        phone: phoneNumber,
        timezone: dayjs.tz.guess(),
      })
      .catch((err) => {
        setMessage(null);
        setError(extractLocalizedError(err));
      });
  };

  return (
    <>
      <p className="text-center mb-0">
        {t("otp.enter_code_sent_to")}
        <br />
        {maskPhoneNumber(phoneNumber)}:
      </p>
      <Form noValidate onSubmit={handleOtpSubmit}>
        <fieldset>
          {/* A legend floats, so its margin doesn't collapse with the code boxes'
              margin the way the old heading's did; mb-4 keeps the same 24px gap. */}
          <legend className="text-center mt-4 mb-4">
            <h1 className="h4 mb-0">{t("otp.verify_code")}</h1>
          </legend>
          <div id="otpContainer" className="d-flex flex-wrap justify-content-center mt-4">
            {otpChars.map((data, index) => (
              <input
                className="otp-field mb-2 p-1"
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
                aria-label={t("otp.enter_code_v2", {
                  index: index + 1,
                  total: OTP_LENGTH,
                })}
                autoComplete="one-time-code"
                // Tell screen reader users up front that focus moves on its own
                // (WCAG 3.2.2). Sighted users see it happen, so it is not shown.
                aria-describedby={index === 0 ? "otpAutoAdvanceNote" : undefined}
              />
            ))}
          </div>
          <span id="otpAutoAdvanceNote" className="visually-hidden">
            {t("otp.auto_advance_note")}
          </span>
        </fieldset>
        <FormError error={error} center className="mb-1" />
        <FormSuccess message={message} center className="mb-1" />
        <p className="text-muted small text-center mt-4">
          {t("otp.did_not_receive")}
          <br />
          <Button
            className="p-0 align-baseline"
            size="sm"
            variant="link"
            onClick={handleResend}
          >
            {t("otp.send_new_code")}
          </Button>
        </p>
        <FormButtons
          back
          primaryProps={{
            children: t("otp.verify"),
            ref: submitRef,
          }}
          variant="outline-primary"
          className="px-3"
        />
      </Form>
    </>
  );
};

export default OneTimePassword;

const OTP_LENGTH = 6;

function otpValid(chars) {
  return chars.every(Boolean);
}

function focusFirstEmptyField(chars) {
  const index = Math.max(
    0,
    chars.findIndex((ch) => !ch)
  );
  document.getElementById("otpContainer")?.children[index]?.focus();
}

function setCharAt(chars, newValue, index) {
  return [...chars.map((num, idx) => (idx === index ? newValue : num))];
}
