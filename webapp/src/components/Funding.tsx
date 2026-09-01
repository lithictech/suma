import api from "../api.ts";
import { r, t } from "../localization";
import { dayjs } from "../modules/dayConfig.ts";
import { AppError, extractAppErrorAny } from "../modules/feedback.ts";
import { scaleMoney } from "../modules/money.ts";
import { isPaymentMethodSupported } from "../modules/paymentMethods.ts";
import { withQuery } from "../routing/withQuery.ts";
import { SetCurrentMember } from "../state/UserProvider.tsx";
import useScreenLoader from "../state/useScreenLoader.ts";
import useToggle, { Toggle } from "../state/useToggle.ts";
import useUser from "../state/useUser";
import Alert from "../ui/Alert.tsx";
import Button from "../ui/Button.tsx";
import Card from "../ui/Card.tsx";
import CardBody from "../ui/CardBody.tsx";
import CardText from "../ui/CardText.tsx";
import { Dialog } from "../ui/Dialog.tsx";
import DialogHeader from "../ui/DialogHeader.tsx";
import Form from "../ui/Form.tsx";
import FormFeedback from "../ui/FormFeedback.tsx";
import FormSubmit from "../ui/FormSubmit.tsx";
import Icon, { IconPropsIcon } from "../ui/Icon.tsx";
import IconButton from "../ui/IconButton.tsx";
import Stack from "../ui/Stack.tsx";
import "./Funding.css";
import {
  BanknotesIcon,
  CheckCircleIcon,
  ClockIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import { AxiosRequestConfig, AxiosResponse } from "axios";
import clsx from "clsx";
import React from "react";

interface UsesUserProps {
  user: CurrentMember;
  setUser: SetCurrentMember;
}

export interface FundingProps extends UsesUserProps {
  supportedPaymentMethods: PaymentMethodType[];
  featureAddFunds: boolean;
}

export default function Funding({
  user,
  setUser,
  supportedPaymentMethods,
  featureAddFunds,
}: FundingProps) {
  return (
    <Stack col gap={4}>
      <p>{t("payments.payment_intro.intro")}</p>
      <p>{t("payments.payment_intro.privacy_statement")}</p>
      <ChargeableCashBalance user={user} setUser={setUser} />
      {isPaymentMethodSupported(supportedPaymentMethods, "card") && (
        <CardsCard
          instruments={user!.paymentInstruments}
          featureAddFunds={featureAddFunds}
        />
      )}
      {isPaymentMethodSupported(supportedPaymentMethods, "bank_account") && (
        <BankAccountsCard
          instruments={user!.paymentInstruments}
          featureAddFunds={featureAddFunds}
        />
      )}
      <AdditionalSourcesCard />
    </Stack>
  );
}

function ChargeableCashBalance({ user, setUser }: UsesUserProps) {
  const [error, setError] = React.useState<AppError | null>();
  const screenLoader = useScreenLoader();

  if (!user!.chargeableCashBalance) {
    return null;
  }

  function handleClick(e: React.MouseEvent) {
    screenLoader.turnOn();
    setError(null);
    e.preventDefault();
    api
      .chargeLedgerBalance()
      .then((r) => setUser(r.data))
      .catch((e: any) => setError(extractAppErrorAny(e)))
      .finally(screenLoader.turnOff);
  }

  const balance = scaleMoney(user!.chargeableCashBalance, -1);

  return (
    <Card className="funding-balance-warning">
      <CardBody className="d-flex flex-column gap-2">
        <div>{t("payments.negative_balance_warning", { amount: balance })}</div>
        <FormFeedback feedback={error} />
        <Button preset="primary" onClick={handleClick}>
          {t("payments.negative_balance_action", { amount: balance })}
        </Button>
      </CardBody>
    </Card>
  );
}

function BankAccountsCard({
  instruments,
  featureAddFunds,
}: {
  instruments: PaymentInstrument[];
  featureAddFunds: boolean;
}) {
  const bankAccounts = instruments.filter(
    (ins) => ins.paymentMethodType === "bank_account"
  );
  return (
    <PaymentsCard header={t("payments.bank_accounts")}>
      {bankAccounts.length === 0 ? (
        <>
          <CardText>{t("payments.no_bank_accounts_warning")}</CardText>
          <Button variant="outline" to="/link-bank-account">
            {t("payments.link_bank_account")}
          </Button>
        </>
      ) : (
        <>
          {bankAccounts.map((ba) => (
            <InstrumentLine
              key={ba.id}
              instrument={ba}
              featureAddFunds={featureAddFunds}
            />
          ))}
          <hr className="my-4" />
          <Button variant="outline" to="/link-bank-account">
            {t("payments.link_another_bank_account")}
          </Button>
        </>
      )}
    </PaymentsCard>
  );
}

function InstrumentLine({
  instrument,
  featureAddFunds,
}: {
  instrument: PaymentInstrument;
  featureAddFunds: boolean;
}) {
  const showDelete = useToggle(false);
  return (
    <Card>
      <CardBody>
        <Stack row center className="justify-content-between">
          <Stack col>
            <Stack row gap={2}>
              {instrument.paymentMethodType === "card" ? (
                <img
                  height="28px"
                  src={`${instrument.institution.logoSrc}`}
                  alt=""
                  style={{ objectFit: "cover" }}
                />
              ) : (
                <Icon icon={BanknotesIcon} size={28} forceSize />
              )}
              <CardText variant="title">{instrument.name}</CardText>
            </Stack>
            <CardText variant="text" className="mt-2">
              {instrument.expiresAt &&
                (instrument.status === "expired" ? (
                  <span className="color-danger">
                    {t("payments.payment_account_expired")}{" "}
                    {dayjs(instrument.expiresAt).format("MM/YY")}
                  </span>
                ) : (
                  <span className="color-text-muted">
                    {t("payments.payment_account_expires")}{" "}
                    {dayjs(instrument.expiresAt).format("MM/YY")}
                  </span>
                ))}
            </CardText>
          </Stack>
          <Stack col gap={2} className="align-items-end">
            <InstrumentStatus instrument={instrument} />
            <Stack row gap={3} center>
              {instrument.usableForFunding && featureAddFunds && (
                <Button
                  variant="filled"
                  color="success"
                  size="sm"
                  to={withQuery(`/add-funds`, {
                    id: instrument.id,
                    paymentMethodType: instrument.paymentMethodType,
                  })}
                >
                  {t("payments.funds")}
                </Button>
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
            </Stack>
          </Stack>
        </Stack>
      </CardBody>
    </Card>
  );
}

function InstrumentStatus({ instrument }: { instrument: PaymentInstrument }) {
  let icon: IconPropsIcon, cls: string, locKey: string;
  if (instrument.status === "ok") {
    icon = CheckCircleIcon;
    cls = "color-success";
    locKey = "payments.payment_account_verified";
  } else if (instrument.status === "unverified") {
    icon = ClockIcon;
    cls = "color-primary";
    locKey = "payments.payment_account_pending";
  } else if (instrument.status === "expired") {
    icon = ClockIcon;
    cls = "color-danger";
    locKey = "payments.payment_account_expired";
  } else {
    return null;
  }
  return (
    <div className={clsx(cls, "d-flex", "align-items-center")}>
      <Icon icon={icon} size={16} />
      &nbsp;{t(locKey)}
    </div>
  );
}

type DeleteFunc = (
  params: {
    id: number;
  },
  cfg?: AxiosRequestConfig
) => Promise<AxiosResponse<MutationPaymentInstrument>>;

interface DeleteInstrumentProps {
  instrument: PaymentInstrument;
  apiMethod: DeleteFunc;
  showDelete: Toggle;
}

function DeleteInstrument({ instrument, apiMethod, showDelete }: DeleteInstrumentProps) {
  return (
    <>
      <IconButton
        icon={TrashIcon}
        variant="text"
        color="danger"
        title={r("payments.unlink_account")}
        onClick={showDelete.turnOn}
      />
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
  apiMethod: DeleteFunc;
  toggle: Toggle;
}

function DeleteInstrumentModal({
  instrument,
  apiMethod,
  toggle,
}: DeleteInstrumentModalProps) {
  const { user, setUser } = useUser();
  const [error, setError] = React.useState<AppError>();
  const screenLoader = useScreenLoader();

  function submitDelete(e: React.FormEvent) {
    screenLoader.turnOn();
    e.preventDefault();
    apiMethod({ id: instrument.id })
      .then((r) =>
        setUser({ ...user!, paymentInstruments: r.data.allPaymentInstruments })
      )
      .catch((e: any) => setError(extractAppErrorAny(e)))
      .finally(screenLoader.turnOff);
  }

  return (
    <Dialog
      open={toggle.isOn}
      onClose={toggle.turnOff}
      labelledBy="delete-instrument-modal-title"
    >
      <Card>
        <CardBody className="d-flex flex-column gap-3">
          <DialogHeader id="delete-instrument-modal-title">
            {t("payments.unlink_account")}
          </DialogHeader>
          <p>{t("payments.unlink_account_question")}</p>
          <Alert
            variant="warning"
            title={t("payments.unlink_account_question_subtitle")}
          />
          <Form onSubmit={submitDelete}>
            <FormSubmit
              feedback={error}
              label={t("payments.unlink")}
              secondary={{ label: r("common.cancel"), onClick: toggle.turnOff }}
            />
          </Form>
        </CardBody>
      </Card>
    </Dialog>
  );
}

function CardsCard({
  instruments,
  featureAddFunds,
}: {
  instruments: PaymentInstrument[];
  featureAddFunds: boolean;
}) {
  const cards = instruments.filter((ins) => ins.paymentMethodType === "card");
  return (
    <PaymentsCard header={t("payments.cards")}>
      {cards.length === 0 ? (
        <>
          <CardText>{t("payments.no_cards_warning")}</CardText>
          <Button variant="outline" to="/add-card">
            {t("payments.add_card")}
          </Button>
        </>
      ) : (
        <>
          {cards.map((c) => (
            <InstrumentLine key={c.id} instrument={c} featureAddFunds={featureAddFunds} />
          ))}
          <Button variant="outline" to="/add-card">
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
      <CardText className="mt-3">{t("payments.payment_support_coming")}</CardText>
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
    <Card>
      <CardBody>
        <Stack col gap={3}>
          <h2>{header}</h2>
          {children}
        </Stack>
      </CardBody>
    </Card>
  );
}
