import api from "../api";
import bankAccountCheckDetails from "../assets/images/bank-account-check-details.gif";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import GoHome from "../components/GoHome";
import TopNav from "../components/TopNav";
import { md } from "../localization/useI18Next";
import useHashToggle from "../shared/react/useHashToggle";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import i18next from "i18next";
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
      <h2>{i18next.t("payments:linked_account")}</h2>
      <p>{md("payments:linked_account_successful_md")}</p>
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
      <h2>{i18next.t("payments:link_account")}</h2>
      <p>{md("payments:payment_intro.privacy_statement_md")}</p>
      <Form noValidate validated={validated} onSubmit={handleSubmit}>
        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>{i18next.t("forms:nickname")}</Form.Label>
            <Form.Control
              required
              type="text"
              value={nickname}
              onChange={(e) => setNickname(e.target.value)}
            />
            <Form.Control.Feedback type="invalid">
              {i18next.t("forms:invalid_nickname")}
            </Form.Control.Feedback>
            <Form.Text>{i18next.t("forms:nickname_caption")}</Form.Text>
          </Form.Group>
        </Row>
        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>{i18next.t("forms:routing_number")}</Form.Label>
            <Form.Control
              required
              type="text"
              pattern="^[0-9]{9}$"
              value={routing}
              onChange={(e) => setRouting(_.replace(e.target.value, /\D/, ""))}
            />
            <Form.Control.Feedback type="invalid">
              {i18next.t("forms:invalid_routing_number")}
            </Form.Control.Feedback>
            <Form.Text>
              {/* #TODO: Combine account_caption including markdown link */}
              {md("forms:routing_caption_md")}
            </Form.Text>
          </Form.Group>
        </Row>
        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>{i18next.t("forms:account_number")}</Form.Label>
            <Form.Control
              required
              type="text"
              pattern="^[0-9 -]+$"
              value={accountNumber}
              onChange={(e) => setAccountNumber(_.replace(e.target.value, /[^\d -]/, ""))}
            />
            <Form.Control.Feedback type="invalid">
              {i18next.t("forms:invalid_account_number")}
            </Form.Control.Feedback>
            <Form.Text>
              {/* #TODO: Combine account_caption including markdown link */}
              {md("forms:account_caption_md")}
            </Form.Text>
          </Form.Group>
        </Row>
        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>{i18next.t("forms:confirm_account_number")}</Form.Label>
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
              {i18next.t("forms:invalid_confirm_account_number")}
            </Form.Control.Feedback>
            <Form.Text>{i18next.t("forms:confirm_account_number_caption")}</Form.Text>
          </Form.Group>
        </Row>

        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>{i18next.t("forms:account_type")}</Form.Label>
            <div>
              <Form.Check
                name="account-type"
                type="radio"
                label={i18next.t("forms:checking")}
                inline
                checked={accountType === "checking"}
                onChange={() => setAccountType("checking")}
              />
              <Form.Check
                name="account-type"
                type="radio"
                label={i18next.t("forms:savings")}
                inline
                checked={accountType === "savings"}
                onChange={() => setAccountType("savings")}
              />
            </div>
            <Form.Text>{i18next.t("forms:account_type_caption")}</Form.Text>
          </Form.Group>
        </Row>

        <p>{i18next.t("payments:account_submission_statement")}</p>
        <FormError error={error} />
        <FormButtons
          variant="success"
          back
          primaryProps={{
            children: i18next.t("forms:continue"),
          }}
        />
        <Modal
          show={showCheckModalToggle.isOn}
          onHide={showCheckModalToggle.turnOff}
          centered
        >
          <Modal.Header closeButton>
            <Modal.Title>{i18next.t("payments:check_details_title")}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>{i18next.t("payments:check_details_subtitle")}</p>
            <img
              src={bankAccountCheckDetails}
              alt={i18next.t("payments:check_detail")}
              className="w-100"
            />
          </Modal.Body>
        </Modal>
      </Form>
    </>
  );
}
