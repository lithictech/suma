import api from "../api";
import BackBreadcrumb from "../components/BackBreadcrumb";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import PageHeading from "../components/PageHeading";
import config from "../config";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import { scaleMoney } from "../shared/money";
import useToggle, { Toggle } from "../shared/react/useToggle";
import useBackendGlobals from "../state/useBackendGlobals";
import { extractErrorCode, useError } from "../state/useError";
import useScreenLoader from "../state/useScreenLoader";
import useUser from "../state/useUser";
import Button from "../ui/Button";
import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import CardHeader from "../ui/CardHeader";
import CardText from "../ui/CardText";
import { Dialog } from "../ui/Dialog";
import DialogHeader from "../ui/DialogHeader";
import Dropdown from "../ui/Dropdown";
import DropdownItem from "../ui/DropdownItem";
import DropdownMenu from "../ui/DropdownMenu";
import DropdownToggle from "../ui/DropdownToggle";
import styles from "./Funding.module.css";
import clsx from "clsx";
import filter from "lodash/filter";
import React from "react";

export default function Funding() {
  const { user } = useUser();
  const { isPaymentMethodSupported } = useBackendGlobals();
  return (
    <>
      <BackBreadcrumb back />
      <PageHeading>{t("payments.payment_title")}</PageHeading>
      <p>{t("payments.payment_intro.intro")}</p>
      <p>{t("payments.payment_intro.privacy_statement")}</p>
      <ChargeableCashBalance />
      {isPaymentMethodSupported("bank_account") && (
        <BankAccountsCard instruments={user.paymentInstruments} />
      )}
      {isPaymentMethodSupported("card") && (
        <CardsCard instruments={user.paymentInstruments} />
      )}
      <AdditionalSourcesCard />
    </>
  );
}

function ChargeableCashBalance() {
  const { user, setUser } = useUser();
  const [error, setError] = useError();
  const screenLoader = useScreenLoader();

  if (!user.chargeableCashBalance) {
    return null;
  }

  function handleClick(e: React.MouseEvent) {
    screenLoader.turnOn();
    setError(null);
    e.preventDefault();
    api
      .chargeLedgerBalance()
      .then((r: any) => setUser(r.data))
      .catch((e: any) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  }

  const balance = scaleMoney(user.chargeableCashBalance, -1);

  return (
    <Card className={styles["balance-warning"]}>
      <CardBody className="d-flex flex-column gap-4">
        <div>{t("payments.negative_balance_warning", { amount: balance })}</div>
        <FormError error={error} noMargin />
        <Button variant="secondary" className="align-self-center" onClick={handleClick}>
          {t("payments.negative_balance_action", { amount: balance })}
        </Button>
      </CardBody>
    </Card>
  );
}

function BankAccountsCard({ instruments }: { instruments: PaymentInstrument[] }) {
  const bankAccounts = filter(instruments, { paymentMethodType: "bank_account" });
  return (
    <PaymentsCard header={t("payments.bank_accounts")}>
      {bankAccounts.length === 0 ? (
        <>
          <CardText>{t("payments.no_bank_accounts_warning")}</CardText>
          <Button variant="outline" href="/link-bank-account">
            {t("payments.link_bank_account")}
          </Button>
        </>
      ) : (
        <>
          {bankAccounts.map((ba) => (
            <InstrumentLine key={ba.id} instrument={ba} />
          ))}
          <hr className="my-4" />
          <Button variant="outline" href="/link-bank-account">
            {t("payments.link_another_bank_account")}
          </Button>
        </>
      )}
    </PaymentsCard>
  );
}

function InstrumentLine({ instrument }: { instrument: PaymentInstrument }) {
  const showDelete = useToggle(false);
  return (
    <Card className="text-start mb-3 funding-card-border-radius shadow-sm">
      <CardBody className="d-flex justify-content-between align-items-center">
        <div>
          <CardText variant="title" className="mb-1">
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
          </CardText>
          <CardText variant="subtitle" className="mt-2">
            {instrument.expiresAt &&
              (instrument.status === "expired" ? (
                <span className="text-danger">
                  {t("payments.payment_account_expired")}{" "}
                  {dayjs(instrument.expiresAt).format("MM/YY")}
                </span>
              ) : (
                <span className="text-muted">
                  {t("payments.payment_account_expires")}{" "}
                  {dayjs(instrument.expiresAt).format("MM/YY")}
                </span>
              ))}
            {instrument.paymentMethodType === "bank_account" && (
              <span className="text-muted">
                {instrument.institution.name} x-{instrument.last4}
              </span>
            )}
          </CardText>
        </div>
        <div className="ms-auto text-end">
          {instrument.usableForFunding && config.featureAddFunds ? (
            <Button
              variant="primary"
              size="sm"
              className="mb-2 funding-card-border-radius text-nowrap"
              href={`/add-funds?id=${instrument.id}&paymentMethodType=${instrument.paymentMethodType}`}
            >
              <i className="bi bi-plus-circle"></i> {t("payments.funds")}
            </Button>
          ) : (
            <Button
              variant="outline"
              size="sm"
              disabled
              className="mb-2 funding-card-border-radius text-nowrap opacity-0"
            >
              &nbsp;
            </Button>
          )}
          <div>
            <InstrumentStatus instrument={instrument} />
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
      </CardBody>
    </Card>
  );
}

function InstrumentStatus({ instrument }: { instrument: PaymentInstrument }) {
  let cls, locKey;
  if (instrument.status === "ok") {
    cls = "bi-check2-circle text-success";
    locKey = "payments.payment_account_verified";
  } else if (instrument.status === "unverified") {
    cls = "bi-stopwatch text-warning";
    locKey = "payments.payment_account_pending";
  } else {
    return null;
  }
  return (
    <small>
      <i className={clsx("bi", cls)}>&nbsp;{t(locKey)}</i>
    </small>
  );
}

interface DeleteInstrumentProps {
  instrument: PaymentInstrument;
  apiMethod: (...args: any[]) => any;
  showDelete: Toggle;
}

function DeleteInstrument({ instrument, apiMethod, showDelete }: DeleteInstrumentProps) {
  return (
    <>
      <Dropdown as="span">
        <DropdownToggle variant="text" className="p-0 ms-2 text-muted" size="sm">
          <i className="bi bi-gear-fill"></i>
        </DropdownToggle>
        <DropdownMenu align="end">
          <DropdownItem className="text-danger" onClick={showDelete.turnOn}>
            {t("payments.unlink_account")}
          </DropdownItem>
        </DropdownMenu>
      </Dropdown>
      <DeleteInstrumentModal
        instrument={instrument}
        apiMethod={apiMethod}
        toggle={showDelete}
      />
    </>
  );
}

interface DeleteInstrumentModalProps {
  instrument: PaymentInstrument;
  apiMethod: (...args: any[]) => any;
  toggle: Toggle;
}

function DeleteInstrumentModal({
  instrument,
  apiMethod,
  toggle,
}: DeleteInstrumentModalProps) {
  const { user, setUser } = useUser();
  const [error, setError] = useError();
  const screenLoader = useScreenLoader();

  function submitDelete(e: React.MouseEvent) {
    screenLoader.turnOn();
    e.preventDefault();
    apiMethod({ id: instrument.id })
      .then((r: any) =>
        setUser({ ...user, paymentInstruments: r.data.allPaymentInstruments })
      )
      .catch((e: any) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  }

  return (
    <Dialog
      open={toggle.isOn}
      onClose={toggle.turnOff}
      labelledBy="delete-instrument-modal-title"
    >
      <DialogHeader id="delete-instrument-modal-title">
        {t("payments.unlink_account")}
      </DialogHeader>
      <p>{t("payments.unlink_account_question")}</p>
      <p>
        <strong>{t("payments.unlink_account_question_subtitle")}</strong>
      </p>
      <FormError error={error} />
      <FormButtons
        variant="secondary"
        primaryProps={{
          children: t("payments.unlink"),
          onClick: submitDelete,
        }}
        secondaryProps={{
          children: t("common.cancel"),
          onClick: toggle.turnOff,
        }}
      />
    </Dialog>
  );
}

function CardsCard({ instruments }: { instruments: PaymentInstrument[] }) {
  const cards = filter(instruments, { paymentMethodType: "card" });
  return (
    <PaymentsCard header={t("payments.cards")}>
      {cards.length === 0 ? (
        <>
          <CardText>{t("payments.no_cards_warning")}</CardText>
          <Button variant="outline" href="/add-card">
            {t("payments.add_card")}
          </Button>
        </>
      ) : (
        <>
          {cards.map((c) => (
            <InstrumentLine key={c.id} instrument={c} />
          ))}
          <hr className="my-4" />
          <Button variant="outline" href="/add-card">
            {t("payments.add_another_card")}
          </Button>
        </>
      )}
    </PaymentsCard>
  );
}

function AdditionalSourcesCard() {
  return (
    <PaymentsCard header={t("payments.payment_other_sources")}>
      <CardText>{t("payments.payment_support_coming")}</CardText>
    </PaymentsCard>
  );
}

function PaymentsCard({
  header,
  children,
}: {
  header: React.ReactNode;
  children?: React.ReactNode;
}) {
  return (
    <Card className="text-center mt-3">
      <CardHeader>
        <h5 className="mb-0">{header}</h5>
      </CardHeader>
      <CardBody>{children}</CardBody>
    </Card>
  );
}
