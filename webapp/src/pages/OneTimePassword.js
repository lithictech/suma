import api from "../api";
import FormError from "../components/FormError";
import FormSuccess from "../components/FormSuccess";
import { dayjs } from "../modules/dayConfig";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, useError } from "../state/useError";
import { useUser } from "../state/useUser";
import React, { useState, useEffect } from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
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
  const { phoneNumber } = state;
  const displayPhoneNumber = phoneNumber
    ? formatPhoneNumber(phoneNumber)
    : "(invalid phone number)";

  useEffect(() => {
    const isEntireCode = otp.every((number) => number !== "");
    if (isEntireCode) {
      submitDisabled.turnOff();
    } else {
      submitDisabled.turnOn();
    }
  }, [submitDisabled, otp]);

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

  const handleOtpSubmit = () => {
    submitDisabled.turnOn();
    setError();
    api
      .authVerify({ phone: phoneNumber, token: otp.join("") })
      .then((r) => {
        setUser(r.data);
        navigate("/dashboard");
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
    setMessage("otp_resent");
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
    <div className="main-container">
      <Row>
        <Col>
          <h2>One Time Code</h2>
          <p className="text-muted small">
            Enter the code that you recieved on the phone number you provided{" "}
            {displayPhoneNumber}
          </p>
          <fieldset>
            <legend className="small">Verify Code</legend>
            <div id="otpContainer">
              {otp.map((data, index) => {
                return (
                  <input
                    className="otp-field"
                    type="text"
                    name="otp"
                    maxLength="1"
                    key={index}
                    value={data}
                    placeholder="&middot;"
                    onChange={(event) => handleOtpChange(event, index)}
                    onFocus={(event) => event.target.select()}
                    autoFocus={index === 0}
                    aria-label={"Enter code " + (index + 1)}
                    autoComplete="one-time-code"
                  />
                );
              })}
            </div>
          </fieldset>
          <FormError error={error} />
          <FormSuccess message={message} />
          <p className="text-muted small">
            Did not recieve a code?{" "}
            <Button className="p-0 align-baseline" variant="link" onClick={handleResend}>
              Resend code again.
            </Button>
          </p>
          <Button
            variant="success d-block mt-3"
            onClick={handleOtpSubmit}
            disabled={submitDisabled.isOn}
          >
            Verify Code
          </Button>
        </Col>
      </Row>
    </div>
  );
};

export default OneTimePassword;
