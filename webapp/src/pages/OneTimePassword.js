import api from "../api";
import FormError from "../components/FormError";
import FormSuccess from "../components/FormSuccess";
import { dayjs } from "../modules/dayConfig";
import { extractErrorCode, useError } from "../state/useError";
import useToggle from "../state/useToggle";
import { useUser } from "../state/useUser";
import React, { useState, useEffect } from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
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
    const firstOtpField = document.getElementById("otpContainer").firstChild;
    setError(null);
    api
      .authStart({
        phone: phoneNumber,
        timezone: dayjs.tz.guess(),
      })
      .then(() => {
        setOtp(new Array(6).fill(""));
        setMessage("otp_resent");
        firstOtpField.focus();
      })
      .catch((err) => {
        setOtp(new Array(6).fill(""));
        setError(extractErrorCode(err));
        firstOtpField.focus();
      });
  };

  return (
    <Container>
      <Row className="justify-content-center">
        <Col className="my-4">
          <h2>Phone Verification</h2>
          <p className="text-muted small">
            Enter the code that you recieved on the phone number you provided{" "}
            {displayPhoneNumber}
          </p>
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
                />
              );
            })}
          </div>
          <FormError error={error} />
          <FormSuccess message={message} />
          <p className="text-muted small">
            Did not recieve a code?{" "}
            <Button className="p-0 align-baseline" variant="link" onClick={handleResend}>Resend code again.</Button>
          </p>
          <Button
            variant="outline-success d-block mt-3"
            onClick={handleOtpSubmit}
            disabled={submitDisabled.isOn}
          >
            Verify Code
          </Button>
        </Col>
      </Row>
    </Container>
  );
};

export default OneTimePassword;
