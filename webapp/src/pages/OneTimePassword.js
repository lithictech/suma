import React, { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { formatPhoneNumber } from 'react-phone-number-input';
import { verifyPhone } from "../api/auth";

import Button from 'react-bootstrap/Button';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';
import Col from 'react-bootstrap/Col';
import useToggle from "../state/useToggle";
import { useError} from "../state/useError";
import FormError from "../components/FormError";

const OneTimePassword = () => {
	const navigate = useNavigate();

	const [otp, setOtp] = useState(new Array(6).fill(""));
	const submitDisabled = useToggle(true);
	const [error, setError] = useError();
	const { state } = useLocation();
	const { phoneNumber } = state;
	const displayPhoneNumber = phoneNumber ? formatPhoneNumber(phoneNumber) : "(invalid phone number)";

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
    if (isNaN(parseInt(value))) return setOtp([...otp.map((num, idx) => (idx === index) ? "" : num)]);
    setOtp([...otp.map((num, idx) => (idx === index) ? value : num)]);

		// Focus next input
		if (target.nextSibling) {
			target.nextSibling.focus();
		}
  }
	const handleOtpSubmit = () => {
		submitDisabled.turnOn();
		const otpCode = otp.join("");
		setError()
		verifyPhone(phoneNumber, otpCode).then(() => {
			return navigate("/dashboard");
		}).catch((err) => {
			setOtp(new Array(6).fill(""));
			setError(err);
			const firstOtpField = document.getElementById("otpContainer").firstChild;
			firstOtpField.focus();
		})
  }

  return (
		<Container>
			<Row className="justify-content-center">
				<Col className="my-4">
					<h2>Phone Verification</h2>
					<p className="text-muted small">Enter the code that you recieved on the phone number you provided {displayPhoneNumber}</p>
					<div id="otpContainer">
						{
							otp.map((data, index) => {
								return (
									<input
										className="otp-field"
										type="text"
										name="otp"
										maxLength="1"
										key={index}
										value={data}
										placeholder="&middot;"
										onChange={event => handleOtpChange(event, index)}
										onFocus={event => event.target.select()}
									/>
								);
							})
						}
					</div>
					<FormError error={error} />
					<p className="text-muted small">Did not recieve a code? <a href={"#TOD-resend-this"} onClick={(e) => e.preventDefault()}>Resend code again.</a></p>
					<Button variant="outline-success d-block mt-3" onClick={handleOtpSubmit} disabled={submitDisabled.isOn}>Verify Code</Button>
				</Col>
			</Row>
		</Container>
	);
}

export default OneTimePassword;
