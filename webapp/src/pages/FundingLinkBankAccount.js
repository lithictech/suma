import api from "../api";
import bankAccountCheckDetails from "../assets/images/bank-account-check-details.gif";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import GoHome from "../components/GoHome";
import TopNav from "../components/TopNav";
import useHashToggle from "../shared/react/useHashToggle";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import i18n from "i18next";
import _ from "lodash";
import React from "react";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Form from "react-bootstrap/Form";
import Modal from "react-bootstrap/Modal";
import Row from "react-bootstrap/Row";
import "react-phone-number-input/style.css";
import { useLocation, useNavigate } from "react-router-dom";

export default function FundingLinkBankAccount() {
  const [submitSuccessful, setSubmitSuccessful] = React.useState(false);

  return (
    <div className="main-container">
      <TopNav />
      <Container>
        {submitSuccessful ? (
          <Success />
        ) : (
          <LinkBankAccount onSuccess={() => setSubmitSuccessful(true)} />
        )}
      </Container>
    </div>
  );
}

function Success() {
  return (
    <>
      <h2>Bank Account Linked</h2>
      <p>
        Your bank account has been successfully linked to Suma. Within the next day or
        two, one of our Member Experience specialists will be in touch to confirm the
        account.
      </p>
      <p>Once the account is confirmed, you&rsquo;ll be able to add funds.</p>
      <GoHome />
    </>
  );
}

function LinkBankAccount({ onSuccess }) {
  const [error, setError] = useError();
  const location = useLocation();
  const navigate = useNavigate();
  const { user, setUser } = useUser();

  const screenLoader = useScreenLoader();
  const showCheckModalToggle = useHashToggle(location, navigate, "check-details");
  const [nickname, setNickname] = React.useState("My Account");
  const [routing, setRouting] = React.useState("111222333");
  const [accountNumber, setAccountNumber] = React.useState("12345");
  const [accountNumberConfirm, setAccountNumberConfirm] = React.useState("12345");
  const [accountType, setAccountType] = React.useState("checking");
  const [validated, setValidated] = React.useState(false);

  const handleSubmit = (event) => {
    const form = event.currentTarget;
    event.preventDefault();
    event.stopPropagation();

    if (form.checkValidity() === false) {
      setValidated(true);
      return;
    }
    screenLoader.turnOn();
    api
      .createBankAccount({
        name: nickname,
        routingNumber: routing,
        accountNumber,
        accountType,
      })
      .then((r) => {
        setUser({ ...user, usablePaymentInstruments: r.data.allPaymentInstruments });
        onSuccess();
      })
      .catch((e) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  };

  return (
    <>
      <h2>Link Bank Account</h2>
      <p>
        Your financial information is secured using <strong>bank-level encryption</strong>{" "}
        and <strong>never shared without your consent</strong>. Please see{" "}
        <a href="#todo">Suma&rsquo;s Privacy Policy</a> for more details about how we
        protect and use your financial information.
      </p>
      <Form noValidate validated={validated} onSubmit={handleSubmit}>
        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>Nickname</Form.Label>
            <Form.Control
              required
              type="text"
              value={nickname}
              onChange={(e) => setNickname(e.target.value)}
            />
            <Form.Control.Feedback type="invalid">
              Please provide a nickname for your account.
            </Form.Control.Feedback>
            <Form.Text>The name used to refer to the account in Suma.</Form.Text>
          </Form.Group>
        </Row>
        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>Routing Number</Form.Label>
            <Form.Control
              required
              type="text"
              pattern="^[0-9]{9}$"
              value={routing}
              onChange={(e) => setRouting(_.replace(e.target.value, /\D/, ""))}
            />
            <Form.Control.Feedback type="invalid">
              Please enter the 9 digit number of your bank account.
            </Form.Control.Feedback>
            <Form.Text>
              9-digit number for your bank. You can get these from your online banking
              portal, or check out{" "}
              <a href="#check-details">
                how to find your bank details from a paper check
              </a>
              .
            </Form.Text>
          </Form.Group>
        </Row>
        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>Account Number</Form.Label>
            <Form.Control
              required
              type="text"
              pattern="^[0-9 -]+$"
              value={accountNumber}
              onChange={(e) => setAccountNumber(_.replace(e.target.value, /[^\d -]/, ""))}
            />
            <Form.Control.Feedback type="invalid">
              Please enter your bank account number.
            </Form.Control.Feedback>
            <Form.Text>
              Number of your bank account. You can get these from your online banking
              portal, or check out{" "}
              <a href="#check-details">
                how to find your bank details from a paper check
              </a>
              .
            </Form.Text>
          </Form.Group>
        </Row>
        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>Confirm Account Number</Form.Label>
            <Form.Control
              required
              type="text"
              pattern="^[0-9 -]+$"
              value={accountNumberConfirm}
              onChange={(e) =>
                setAccountNumberConfirm(_.replace(e.target.value, /[^\d -]/, ""))
              }
            />
            <Form.Control.Feedback type="invalid">
              Must match your Account Number above.
            </Form.Control.Feedback>
            <Form.Text>Please retype your Account Number to confirm.</Form.Text>
          </Form.Group>
        </Row>

        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>Account Type</Form.Label>
            <div>
              <Form.Check
                name="account-type"
                type="radio"
                label="Checking"
                inline
                checked={accountType === "checking"}
                onChange={() => setAccountType("checking")}
              />
              <Form.Check
                name="account-type"
                type="radio"
                label="Savings"
                inline
                checked={accountType === "savings"}
                onChange={() => setAccountType("savings")}
              />
            </div>
            <Form.Text>
              Choose which type of account this is. If you&rsquo;re not sure, use
              Checking.
            </Form.Text>
          </Form.Group>
        </Row>

        <p>
          After you submit your information, one of our Member Experience specialists will
          be in touch to confirm the account.
        </p>
        <FormError error={error} />
        <FormButtons
          variant="success"
          back
          primaryProps={{
            children: i18n.t("continue", { ns: "forms" }),
          }}
        />
        <Modal
          show={showCheckModalToggle.isOn}
          onHide={showCheckModalToggle.turnOff}
          centered
        >
          <Modal.Header closeButton>
            <Modal.Title>What is my Account Number?</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>
              At the bottom of your check are three sets of numbers. The first is the
              9-digit routing number. The second is your account number. The third, which
              you can ignore, is your check number.
            </p>
            <img src={bankAccountCheckDetails} alt="check detail" className="w-100" />
          </Modal.Body>
        </Modal>
        <Modal
          show={showCheckModalToggle.isOn}
          onHide={showCheckModalToggle.turnOff}
          centered
        >
          <Modal.Header closeButton>
            <Modal.Title>What is my Account Number?</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>
              At the bottom of your check are three sets of numbers. The first is the
              9-digit routing number. The second is your account number. The third, which
              you can ignore, is your check number.
            </p>
            <img src={bankAccountCheckDetails} alt="check detail" className="w-100" />
          </Modal.Body>
        </Modal>
      </Form>
    </>
  );
}
