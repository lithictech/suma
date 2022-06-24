import api from "../api";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import RLink from "../components/RLink";
import { md, t } from "../localization";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Container from "react-bootstrap/Container";
import Dropdown from "react-bootstrap/Dropdown";
import Modal from "react-bootstrap/Modal";
import "react-phone-number-input/style.css";

export default function Funding() {
  const { user } = useUser();
  return (
    <Container>
      <h2>{t("payments:payment_title")}</h2>
      <p>{md("payments:payment_intro.intro_md")}</p>
      <p id="some">{md("payments:payment_intro.privacy_statement_md")}</p>
      <BankAccountsCard instruments={user.usablePaymentInstruments} />
      <AdditionalSourcesCard />
    </Container>
  );
}

function BankAccountsCard({ instruments }) {
  const bankAccounts = _.filter(instruments, { paymentMethodType: "bank_account" });
  return (
    <PaymentsCard header={t("payments:bank_accounts")}>
      {bankAccounts.length === 0 ? (
        <>
          <Card.Text>{t("payments:no_bank_accounts_warning")}</Card.Text>
          <Button variant="primary" href="/link-bank-account" as={RLink}>
            {t("payments:link_account")}
          </Button>
        </>
      ) : (
        <>
          {bankAccounts.map((ba) => (
            <BankAccountLine key={ba.id} bankAccount={ba} />
          ))}
          <hr className="my-4" />
          <Button variant="primary" href="/link-bank-account" as={RLink}>
            {t("payments:link_another_account")}
          </Button>
        </>
      )}
    </PaymentsCard>
  );
}

function BankAccountLine({ bankAccount }) {
  const { user, setUser } = useUser();
  const [error, setError] = useError();
  const screenLoader = useScreenLoader();
  const showDelete = useToggle(false);
  function submitDelete(e) {
    screenLoader.turnOn();
    e.preventDefault();
    api
      .deleteBankAccount({ id: bankAccount.id })
      .then((r) =>
        setUser({ ...user, usablePaymentInstruments: r.data.allPaymentInstruments })
      )
      .catch((e) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  }
  return (
    <Card className="text-start mb-3 funding-card-border-radius">
      <Card.Body className="d-flex justify-content-between align-items-center">
        <div>
          <Card.Title className="mb-1" as="h6">
            <i className="bi bi-bank2 me-2"></i>
            {bankAccount.display.name}
          </Card.Title>
          <Card.Subtitle className="m-0">
            <span className="opacity-50">x-{bankAccount.display.last4}</span>
          </Card.Subtitle>
        </div>
        <div className="ms-auto text-end">
          {bankAccount.canUseForFunding ? (
            <Button
              variant="success"
              size="sm"
              className="mb-2 funding-card-border-radius nowrap"
              href={`/add-funds?id=${bankAccount.id}&paymentMethodType=bank_account`}
              as={RLink}
            >
              <i className="bi bi-plus-circle"></i> {t("payments:add_funds")}
            </Button>
          ) : (
            <Button size="sm" className="opacity-0" disabled aria-hidden>
              &nbsp;{/* Match verified account sizing so cards are same size*/}
            </Button>
          )}
          <div>
            {bankAccount.canUseForFunding ? (
              <small>
                <i className="bi bi-check2-circle text-success" title="Verified account">
                  {t("payments:payment_account_verified")}
                </i>
              </small>
            ) : (
              <small>
                <i className="bi bi-stopwatch text-warning" title="Verification pending">
                  {t("payments:payment_account_pending")}
                </i>
              </small>
            )}
            <Dropdown as="span">
              <Dropdown.Toggle variant="link" className="p-0 ms-2 text-muted" size="sm">
                <i className="bi bi-gear-fill"></i>
              </Dropdown.Toggle>
              <Dropdown.Menu align="end">
                <Dropdown.Item className="text-danger" onClick={showDelete.turnOn}>
                  {t("payments:unlink_account")}
                </Dropdown.Item>
              </Dropdown.Menu>
            </Dropdown>
          </div>
        </div>
      </Card.Body>
      <Modal show={showDelete.isOn} onHide={showDelete.turnOff} centered>
        <Modal.Header closeButton>
          <Modal.Title as="h5">{t("payments:unlink_account")}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>{t("payments:unlink_account_question")}</p>
          <p>
            <strong>{t("payments:unlink_account_question_subtitle")}</strong>
          </p>
          <FormError error={error} />
          <FormButtons
            variant="danger"
            primaryProps={{
              children: t("payments:unlink"),
              onClick: submitDelete,
            }}
            secondaryProps={{
              children: t("common:cancel"),
              onClick: showDelete.turnOff,
            }}
          />
        </Modal.Body>
      </Modal>
    </Card>
  );
}

function AdditionalSourcesCard() {
  return (
    <PaymentsCard header={t("payments:payment_other_sources")}>
      <Card.Text>{t("payments:payment_support_coming")}</Card.Text>
      <Button variant="link" href="#todo">
        {t("common:learn_more")}
      </Button>
    </PaymentsCard>
  );
}

function PaymentsCard({ header, children }) {
  return (
    <Card className="text-center mt-3">
      <Card.Header>
        <h5 className="mb-0">{header}</h5>
      </Card.Header>
      <Card.Body>{children}</Card.Body>
    </Card>
  );
}
