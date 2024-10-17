import api from "../api";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import RLink from "../components/RLink";
import config from "../config";
import { t } from "../localization";
import useToggle from "../shared/react/useToggle";
import useBackendGlobals from "../state/useBackendGlobals";
import { extractErrorCode, useError } from "../state/useError";
import useScreenLoader from "../state/useScreenLoader";
import useUser from "../state/useUser";
import filter from "lodash/filter";
import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Dropdown from "react-bootstrap/Dropdown";
import Modal from "react-bootstrap/Modal";

export default function Funding() {
  const { user } = useUser();
  const { isPaymentMethodSupported } = useBackendGlobals();
  return (
    <>
      <LinearBreadcrumbs back />
      <h2 className="page-header">{t("payments:payment_title")}</h2>
      <p>{t("payments:payment_intro.intro")}</p>
      <p id="some">{t("payments:payment_intro.privacy_statement")}</p>
      {isPaymentMethodSupported("bank_account") && (
        <BankAccountsCard instruments={user.usablePaymentInstruments} />
      )}
      {isPaymentMethodSupported("card") && (
        <CardsCard instruments={user.usablePaymentInstruments} />
      )}
      <AdditionalSourcesCard />
    </>
  );
}

function BankAccountsCard({ instruments }) {
  const bankAccounts = filter(instruments, { paymentMethodType: "bank_account" });
  return (
    <PaymentsCard header={t("payments:bank_accounts")}>
      {bankAccounts.length === 0 ? (
        <>
          <Card.Text>{t("payments:no_bank_accounts_warning")}</Card.Text>
          <Button variant="outline-primary" href="/link-bank-account" as={RLink}>
            {t("payments:link_bank_account")}
          </Button>
        </>
      ) : (
        <>
          {bankAccounts.map((ba) => (
            <InstrumentLine key={ba.id} instrument={ba} />
          ))}
          <hr className="my-4" />
          <Button variant="outline-primary" href="/link-bank-account" as={RLink}>
            {t("payments:link_another_bank_account")}
          </Button>
        </>
      )}
    </PaymentsCard>
  );
}

function InstrumentLine({ instrument }) {
  const showDelete = useToggle(false);
  return (
    <Card className="text-start mb-3 funding-card-border-radius shadow-sm">
      <Card.Body className="d-flex justify-content-between align-items-center">
        <div>
          <Card.Title className="mb-1" as="h6">
            {instrument.paymentMethodType === "card" ? (
              <img
                className="me-2"
                width="28px"
                src={`${instrument.institution.logoSrc}`}
                alt=""
              />
            ) : (
              <i className="bi bi-bank2 me-2"></i>
            )}
            {instrument.name}
          </Card.Title>
          <Card.Subtitle className="m-0">
            <span className="opacity-50">x-{instrument.last4}</span>
          </Card.Subtitle>
        </div>
        <div className="ms-auto text-end">
          {instrument.canUseForFunding && config.featureAddFunds ? (
            <Button
              variant="success"
              size="sm"
              className="mb-2 funding-card-border-radius nowrap"
              href={`/add-funds?id=${instrument.id}&paymentMethodType=${instrument.paymentMethodType}`}
              as={RLink}
            >
              <i className="bi bi-plus-circle"></i> {t("payments:funds")}
            </Button>
          ) : (
            <Button
              variant="outline-secondary"
              size="sm"
              disabled
              className="mb-2 funding-card-border-radius nowrap opacity-0"
            >
              &nbsp;
            </Button>
          )}
          <div>
            {instrument.canUseForFunding ? (
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
            <DeleteInstrument
              instrument={instrument}
              apiMethod={
                instrument.paymentMethodType === "card"
                  ? api.deleteCard
                  : api.deleteBankAccount
              }
              showDelete={showDelete}
            />
          </div>
        </div>
      </Card.Body>
    </Card>
  );
}

function DeleteInstrument({ instrument, apiMethod, showDelete }) {
  return (
    <>
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
      <DeleteInstrumentModal
        instrument={instrument}
        apiMethod={apiMethod}
        toggle={showDelete}
      />
    </>
  );
}

function DeleteInstrumentModal({ instrument, apiMethod, toggle }) {
  const { user, setUser } = useUser();
  const [error, setError] = useError();
  const screenLoader = useScreenLoader();

  function submitDelete(e) {
    screenLoader.turnOn();
    e.preventDefault();
    apiMethod({ id: instrument.id })
      .then((r) =>
        setUser({ ...user, usablePaymentInstruments: r.data.allPaymentInstruments })
      )
      .catch((e) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  }

  return (
    <Modal show={toggle.isOn} onHide={toggle.turnOff} centered>
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
            onClick: toggle.turnOff,
          }}
        />
      </Modal.Body>
    </Modal>
  );
}

function CardsCard({ instruments }) {
  const cards = filter(instruments, { paymentMethodType: "card" });
  return (
    <PaymentsCard header={t("payments:cards")}>
      {cards.length === 0 ? (
        <>
          <Card.Text>{t("payments:no_cards_warning")}</Card.Text>
          <Button variant="outline-primary" href="/add-card" as={RLink}>
            {t("payments:add_card")}
          </Button>
        </>
      ) : (
        <>
          {cards.map((c) => (
            <InstrumentLine key={c.id} instrument={c} />
          ))}
          <hr className="my-4" />
          <Button variant="outline-primary" href="/add-card" as={RLink}>
            {t("payments:add_another_card")}
          </Button>
        </>
      )}
    </PaymentsCard>
  );
}

function AdditionalSourcesCard() {
  return (
    <PaymentsCard header={t("payments:payment_other_sources")}>
      <Card.Text>{t("payments:payment_support_coming")}</Card.Text>
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
