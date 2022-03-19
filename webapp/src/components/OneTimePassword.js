import React, { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { formatPhoneNumber } from 'react-phone-number-input';
import { verifyPhone } from "../api/auth";
import errorMsg from "../constants/errorMessages";

import Button from 'react-bootstrap/Button';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';
import Col from 'react-bootstrap/Col';

const OneTimePassword = (props) => {
	const navigate = useNavigate();

	const [otp, setOtp] = useState(new Array(6).fill(""));
	const [isSubmitDisabled, setIsSubmitDisabled] = useState(true);
	const [isWarningHidden, setIsWarningHidden] = useState(true);
	const [warningMsg, setWarningMsg] = useState(errorMsg.invalidToken);
	const location = useLocation();
	console.log(location)
	// const { phoneNumber } = state;
	const phoneNumber = "+19192847284"
	// console.log(handleStartFetch);
	const displayPhoneNumber = phoneNumber ? formatPhoneNumber(phoneNumber) : "invalid phone number.";

	useEffect(() => {
		const isEntireCode = otp.every((number) => number !== "");
		if (isEntireCode) {
			setIsSubmitDisabled(false);
		} else {
			setIsSubmitDisabled(true);
		}
	}, [setIsSubmitDisabled, otp]);

	const handleOtpChange = (event, index) => {
		const { target } = event;
		const { value } = target;
		if (isNaN(value)) return setOtp([...otp.map((num, idx) => (idx === index) ? "" : num)]);
		setOtp([...otp.map((num, idx) => (idx === index) ? value : num)])

		// Focus next input
		if (target.nextSibling) {
			target.nextSibling.focus();
		};
	}
	const displayWarningMessage = (<p className="d-block text-danger small">{warningMsg}</p>);
	const handleOtpSubmit = () => {
		setIsSubmitDisabled(true);
		const otpCode = otp.join("");
		const verifyPhoneNumber = phoneNumber.replace(/^\+/g, '');

		// TODO: handle redirect to onBoarding if user doesn't exist
		verifyPhone(verifyPhoneNumber, otpCode).then((response) => {
			if (response) {
				setIsWarningHidden(true);
				return navigate("/dashboard");
			} else {
				setWarningMsg("Unexpected error occured. Please try again.");
				setIsWarningHidden(false);
			}
		}).catch((error) => {
			if (error) {
				const firstOtpField = document.getElementById("otpContainer").firstChild;

				setOtp([...otp.map((num) => num = "")]);
				setWarningMsg(error);
				setIsWarningHidden(false);
				firstOtpField.focus();
			}
		});

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
					{isWarningHidden ? "" : displayWarningMessage}
					<p className="text-muted small">Did not recieve a code? <a href="./start">Resend code again.</a></p>

					<Button variant="outline-success d-block mt-3" onClick={handleOtpSubmit} disabled={isSubmitDisabled}>Verify Code</Button>
				</Col>
			</Row>
		</Container>
	);
}

export default OneTimePassword;
