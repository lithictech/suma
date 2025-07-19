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
      submitRef.current.disabled = false;
      submitRef.current.focus();
      return;
    }

    // The number we just typed is to the left of the cursor location.
    const newlyTypedChar = value[event.target.selectionStart - 1];
    const newOtp = setCharAt(otpChars, newlyTypedChar, index);
    setOtpChars(newOtp);

    submitRef.current.disabled = !otpValid(newOtp);
    if (target.nextSibling) {
      // Focus next input if there is one.
      target.nextSibling.focus();
    } else if (submitRef.current) {
      // Focus submit if we're at the last input (will only focus if it's not disabled)
      submitRef.current.focus();
    }
  };

  const handleOtpKeyDown = (event, index) => {
    const { key, target } = event;
    if (key === "Backspace" || key === "Delete") {
      event.preventDefault();
      submitRef.current.disabled = true;
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
    submitRef.current.disabled = false;
    submitRef.current.focus();
  };

  const handleOtpSubmit = (e) => {
    e.preventDefault();
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

  const handleSubmitRef = React.useCallback((r) => {
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
    <>
      <p className="text-center mb-0">
        {t("otp.enter_code_sent_to")}
        <br />
        {maskPhoneNumber(phoneNumber)}:
      </p>
      <Form noValidate onSubmit={handleOtpSubmit}>
        <fieldset>
          <h4 className="text-center mt-4">{t("otp.verify_code")}</h4>
          <div id="otpContainer" className="d-flex justify-content-center mt-4">
            {otpChars.map((data, index) => (
              <input
                className="otp-field mb-2 p-1"
                type="numbers"
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
                aria-label={t("otp.enter_code", { index: index + 1 })}
                autoComplete="one-time-code"
              />
            ))}
          </div>
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
            ref: handleSubmitRef,
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

function setCharAt(chars, newValue, index) {
  return [...chars.map((num, idx) => (idx === index ? newValue : num))];
}
