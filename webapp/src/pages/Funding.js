import api from "../api";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import RLink from "../components/RLink";
import TopNav from "../components/TopNav";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import _ from "lodash";
import React from "react";
import { Card, Modal } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";
import "react-phone-number-input/style.css";

export default function Funding() {
  const { user } = useUser();

  return (
    <div className="main-container">
      <TopNav />
      <Container>
        <h2>Payment Accounts</h2>
        <p>
          To add money to your account, you&rsquo;ll need at least one{" "}
          <em>funding source</em>. Usually this is a bank account, but other options may
          be available to you below.
        </p>
        <p>
          Your financial information is secured using{" "}
          <strong>bank-level encryption</strong> and{" "}
          <strong>never shared without your consent</strong>. Please see{" "}
          <a href="#todo">Suma&rsquo;s Privacy Policy</a> for more details about how we
          protect and use your financial information.
        </p>
        <BankAccountsCard instruments={user.usablePaymentInstruments} />
        <AdditionalSourcesCard />
      </Container>
    </div>
  );
}

function BankAccountsCard({ instruments }) {
  const bankAccounts = _.filter(instruments, { paymentMethodType: "bank_account" });
  return (
    <PaymentsCard header="Bank Accounts">
      <Card.Body>
        {bankAccounts.length === 0 ? (
          <>
            <Card.Text>You don&rsquo;t have any bank accounts linked.</Card.Text>
            <Button variant="primary" href="/link-bank-account" as={RLink}>
              Link Bank Account
            </Button>
          </>
        ) : (
          <>
            {bankAccounts.map((ba) => (
              <BankAccountLine key={ba.id} bankAccount={ba} />
            ))}
            <hr className="my-4" />
            <Button variant="primary" href="/link-bank-account" as={RLink}>
              Link Another Account
            </Button>
          </>
        )}
      </Card.Body>
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
    <div className="my-3 d-flex justify-content-between align-items-center">
      <div className="me-2">
        <i className="bi bi-bank2 me-2"></i>
        <strong className="text-nowrap">{bankAccount.display.name}</strong>{" "}
        <span className="text-nowrap">x-{bankAccount.display.last4}</span>
        {bankAccount.canUseForFunding ? (
          <i
            className="bi bi-check2-circle text-success ms-2"
            title="Verified account"
          ></i>
        ) : (
          <i
            className="bi bi-stopwatch text-warning ms-2"
            title="Verification pending"
          ></i>
        )}
      </div>
      {bankAccount.canUseForFunding && (
        <div className="mx-2">
          <Button
            variant="success"
            href={`/add-funds?id=${bankAccount.id}&paymentMethodType=bank_account`}
            as={RLink}
          >
            <i className="bi bi-cash-stack" title="Add Funds"></i>
          </Button>
        </div>
      )}
      <div className="ms-2">
        <Button variant="outline-danger" className="border-0" onClick={showDelete.turnOn}>
          <i className="bi bi-x-circle-fill" title="Unlink bank account"></i>
        </Button>
      </div>
      <Modal show={showDelete.isOn} onHide={showDelete.turnOff} centered>
        <Modal.Header closeButton>
          <Modal.Title>Unlink Account?</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            Are you sure you want to unlink this account? You can always re-add it later.
          </p>
          <p>
            <strong>Any in-progress transactions will not be canceled.</strong>
          </p>
          <FormError error={error} />
          <FormButtons
            variant="primary"
            primaryProps={{
              children: "Unlink",
              onClick: submitDelete,
            }}
            secondaryProps={{
              children: "Cancel",
              onClick: showDelete.turnOff,
            }}
          />
        </Modal.Body>
      </Modal>
    </div>
  );
}

function AdditionalSourcesCard() {
  return (
    <PaymentsCard header="Other Sources">
      <Card.Text>
        Support is coming for additional sources, such as cash, money order, and adding
        funds through a friend.
      </Card.Text>
      <Button variant="link" href="#todo">
        Learn More
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
