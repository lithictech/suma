import api from "../api";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import FormSuccess from "../components/FormSuccess";
import { md, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, useError } from "../state/useError";
import { useUser } from "../state/useUser";
import React, { useState, useEffect } from "react";
import { Form } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import { formatPhoneNumber } from "react-phone-number-input";
import { useNavigate, useLocation } from "react-router-dom";

const OneTimePassword = () => {
  const navigate = useNavigate();
  const { setUser } = useUser();
  const [otp, setOtp] = useState(new Array(6).fill(""));
  const submitDisabled = useToggle(true);
  const [error, setError] = useError();
  const [message, setMessage] = useState();
  const { state } = useLocation();
  const phoneNumber = state ? state.phoneNumber : undefined;
  const requireTerms = state ? state.requiresTermsAgreement : true;

  React.useEffect(() => {
    if (!phoneNumber) {
      navigate("/start", { replace: true });
    }
  }, [navigate, phoneNumber]);

  useEffect(() => {
    const isEntireCode = otp.every((number) => number !== "");
    if (isEntireCode) {
      submitDisabled.turnOff();
    } else {
      submitDisabled.turnOn();
    }
  }, [navigate, submitDisabled, otp]);

  const handleOtpChange = (event, index) => {
    const { target } = event;
    const { value } = target;
    if (isNaN(parseInt(value)))
      return setOtp([...otp.map((num, idx) => (idx === index ? "" : num))]);
    setOtp([...otp.map((num, idx) => (idx === index ? value : num))]);

    // Focus next input
    if (target.nextSibling) {
      target.nextSibling.focus();
    }
  };

  const handleOtpSubmit = (e) => {
    e.preventDefault();
    submitDisabled.turnOn();
    setError();
    api
      .authVerify({ phone: phoneNumber, token: otp.join(""), termsAgreed: true })
      .then((r) => {
        setUser(r.data);
        if (r.data.onboarded) {
          navigate("/dashboard");
        } else {
          navigate("/onboarding");
        }
      })
      .catch((err) => {
        setOtp(new Array(6).fill(""));
        setMessage(null);
        setError(extractErrorCode(err));
        const firstOtpField = document.getElementById("otpContainer").firstChild;
        firstOtpField.focus();
      });
  };

  const handleResend = () => {
    setOtp(new Array(6).fill(""));
    setError(null);
    setMessage(["otp:code_resent", { phone: formatPhoneNumber(phoneNumber) }]);
    const firstOtpField = document.getElementById("otpContainer").firstChild;
    firstOtpField.focus();
    api
      .authStart({
        phone: phoneNumber,
        timezone: dayjs.tz.guess(),
      })
      .catch((err) => {
        setMessage(null);
        setError(extractErrorCode(err));
      });
  };

  return (
    <>
      <p className="text-center mb-0">
        {t("otp:enter_code_sent_to")}
        <br />
        {formatPhoneNumber(phoneNumber)}:
      </p>
      <Form noValidate onSubmit={handleOtpSubmit}>
        <fieldset>
          <h4 className="text-center mt-4">{t("otp:verify_code")}</h4>
          <div id="otpContainer" className="d-flex justify-content-center mt-4">
            {otp.map((data, index) => (
              <input
                className="otp-field mb-2 p-1"
                type="text"
                name="otp"
                maxLength="1"
                inputMode="numeric"
                key={index}
                value={data}
                placeholder="&middot;"
                onChange={(event) => handleOtpChange(event, index)}
                onFocus={(event) => event.target.select()}
                autoFocus={index === 0}
                aria-label={t("otp:enter_code") + (index + 1)}
                autoComplete="one-time-code"
              />
            ))}
          </div>
        </fieldset>
        <FormError error={error} center className="mb-1" />
        <FormSuccess message={message} center className="mb-1" />
        <p className="text-muted small text-center mt-4">
          {t("otp:did_not_receive")}
          <br />
          <Button
            className="p-0 align-baseline"
            size="sm"
            variant="link"
            onClick={handleResend}
          >
            {t("otp:send_new_code")}
          </Button>
        </p>
        {requireTerms && <p className="w-75 text-center m-auto">{md("otp:terms_md")}</p>}
        <FormButtons
          back
          primaryProps={{
            children: t("otp:verify"),
            disabled: submitDisabled.isOn,
          }}
          variant="outline-primary"
          className="px-3"
        />
      </Form>
    </>
  );
};

export default OneTimePassword;
