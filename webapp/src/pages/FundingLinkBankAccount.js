import api from "../api";
import bankAccountCheckDetails from "../assets/images/bank-account-check-details.gif";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import GoHome from "../components/GoHome";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import { md, mdp, t } from "../localization";
import keepDigits from "../modules/keepDigits";
import useHashToggle from "../shared/react/useHashToggle";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import React from "react";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Modal from "react-bootstrap/Modal";
import Row from "react-bootstrap/Row";
import { useForm } from "react-hook-form";
import "react-phone-number-input/style.css";
import { useLocation, useNavigate } from "react-router-dom";

export default function FundingLinkBankAccount() {
  const [submitSuccessful, setSubmitSuccessful] = React.useState(false);
  return (
    <>
      {submitSuccessful ? (
        <Success />
      ) : (
        <LinkBankAccount onSuccess={() => setSubmitSuccessful(true)} />
      )}
    </>
  );
}

function Success() {
  return (
    <>
      <h2>{t("payments:linked_account")}</h2>
      {mdp("payments:linked_account_successful_md")}
      <GoHome />
    </>
  );
}

function LinkBankAccount({ onSuccess }) {
  const {
    register,
    handleSubmit,
    clearErrors,
    setValue,
    formState: { errors },
  } = useForm({
    mode: "all",
  });
  const [error, setError] = useError();
  const { user, setUser, handleUpdateCurrentMember } = useUser();

  const screenLoader = useScreenLoader();
  const showCheckModalToggle = useHashToggle("check-details");
  const [nickname, setNickname] = React.useState("");
  const [routing, setRouting] = React.useState("");
  const [accountNumber, setAccountNumber] = React.useState("");
  const [accountNumberConfirm, setAccountNumberConfirm] = React.useState("");
  const [accountType, setAccountType] = React.useState("checking");

  const handleFormSubmit = () => {
    screenLoader.turnOn();
    api
      .createBankAccount({
        name: nickname,
        routingNumber: routing,
        accountNumber,
        accountType,
      })
      .tap(handleUpdateCurrentMember)
      .then((r) => {
        setUser({ ...user, usablePaymentInstruments: r.data.allPaymentInstruments });
        onSuccess();
      })
      .catch((e) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  };
  const runSetter = (name, set, value) => {
    clearErrors(name);
    setValue(name, value);
    set(value);
  };

  return (
    <>
      <LinearBreadcrumbs back />
      <h2 className="page-header">{t("payments:link_account")}</h2>
      <p>{md("payments:payment_intro.privacy_statement_md")}</p>
      <Form noValidate onSubmit={handleSubmit(handleFormSubmit)}>
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            required
            type="text"
            name="nickname"
            label={t("forms:nickname")}
            text={t("forms:nickname_caption")}
            value={nickname}
            errors={errors}
            register={register}
            onChange={(e) => runSetter(e.target.name, setNickname, e.target.value)}
          />
        </Row>
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            required
            type="text"
            pattern="^[0-9]{9}$"
            inputMode="numeric"
            name="routing_number"
            label={t("forms:routing_number")}
            text={md("forms:routing_caption_md")}
            value={routing}
            errors={errors}
            errorKeys={{ pattern: "forms:invalid_routing_number" }}
            register={register}
            onChange={(e) =>
              runSetter(e.target.name, setRouting, keepDigits(e.target.value))
            }
          />
        </Row>
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            required
            type="text"
            pattern="^\d{3}\d+$"
            inputMode="numeric"
            name="account_number"
            label={t("forms:account_number")}
            text={md("forms:account_caption_md")}
            value={accountNumber}
            errors={errors}
            errorKeys={{ pattern: "forms:invalid_account_number" }}
            register={register}
            onChange={(e) =>
              runSetter(e.target.name, setAccountNumber, keepDigits(e.target.value))
            }
          />
        </Row>
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            type="text"
            inputMode="numeric"
            name="confirm_account_number"
            label={t("forms:confirm_account_number")}
            text={t("forms:confirm_account_number_caption")}
            value={accountNumberConfirm}
            errors={errors}
            errorKeys={{ validate: "forms:invalid_confirm_account_number" }}
            register={register}
            registerOptions={{ validate: (v) => v === accountNumber }}
            onChange={(e) =>
              runSetter(
                e.target.name,
                setAccountNumberConfirm,
                keepDigits(e.target.value)
              )
            }
          />
        </Row>
        <Row className="mb-3">
          <Form.Group as={Col}>
            <Form.Label>{t("forms:account_type")}</Form.Label>
            <div>
              <Form.Check
                inline
                id="cheking"
                name="account-type"
                type="radio"
                label={t("forms:checking")}
                checked={accountType === "checking"}
                onChange={() => setAccountType("checking")}
              />
              <Form.Check
                inline
                id="savings"
                name="account-type"
                type="radio"
                label={t("forms:savings")}
                checked={accountType === "savings"}
                onChange={() => setAccountType("savings")}
              />
            </div>
            <Form.Text>{t("forms:account_type_caption")}</Form.Text>
          </Form.Group>
        </Row>

        <p>{t("payments:account_submission_statement")}</p>
        <FormError error={error} />
        <FormButtons
          variant="outline-primary"
          back
          primaryProps={{
            children: t("forms:continue"),
          }}
        />
        <Modal
          show={showCheckModalToggle.isOn}
          onHide={showCheckModalToggle.turnOff}
          centered
        >
          <Modal.Header closeButton>
            <Modal.Title>{t("payments:check_details_title")}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>{t("payments:check_details_subtitle")}</p>
            <img
              src={bankAccountCheckDetails}
              alt={t("payments:check_detail")}
              className="w-100"
            />
          </Modal.Body>
        </Modal>
      </Form>
    </>
  );
}
