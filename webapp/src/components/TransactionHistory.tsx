import { IdParams } from "../api.ts";
import { r, t } from "../localization";
import { AppError, extractAppErrorAny } from "../modules/feedback.ts";
import useAsyncFetch from "../state/useAsyncFetch.ts";
import useHashSelector from "../state/useHashSelector.ts";
import Button from "../ui/Button.tsx";
import Card from "../ui/Card.tsx";
import CardBody from "../ui/CardBody.tsx";
import CardText from "../ui/CardText.tsx";
import { Dialog } from "../ui/Dialog.tsx";
import DialogHeader from "../ui/DialogHeader.tsx";
import FormFeedback from "../ui/FormFeedback.tsx";
import ForwardBackPagination from "../ui/ForwardBackPagination.tsx";
import IndeterminateLoader from "../ui/IndeterminateLoader.tsx";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import Select from "../ui/Select.tsx";
import Stack from "../ui/Stack.tsx";
import Table from "../ui/Table.tsx";
import Money from "../uir/Money.tsx";
import AsyncContent from "./AsyncContent.tsx";
import { AxiosRequestConfig, AxiosResponse } from "axios";
import clsx from "clsx";
import dayjs from "dayjs";
import isEmpty from "lodash/isEmpty";
import React from "react";

interface TransactionHistoryProps {
  ledgersOverview: LedgersView;
  loading?: boolean;
  error?: AppError | null;
  getLedgerLines: (
    params: IdParams,
    cfg?: AxiosRequestConfig
  ) => Promise<AxiosResponse<LedgerLines>>;
  ledgerId: number | null;
  setLedgerId: (ledgerId: number) => void;
  ledgerLinesPage: number;
  setLedgerLinesPage: (page: number) => void;
  /** Only use during testing. */
  fetchLinesOnInit?: boolean;
  initialLedgerLines?: LedgerLines;
}
export default function TransactionHistory({
  ledgersOverview,
  loading,
  error,
  ledgerId,
  setLedgerId,
  getLedgerLines,
  ledgerLinesPage,
  setLedgerLinesPage,
  fetchLinesOnInit,
  initialLedgerLines,
}: TransactionHistoryProps) {
  const fetchLedgerLines = React.useCallback(
    (data?: Record<string, any>) => getLedgerLines(data as IdParams),
    [getLedgerLines]
  );

  const {
    state: ledgerLines,
    loading: ledgerLinesLoading,
    error: ledgerLinesError,
    asyncFetch: ledgerLinesFetch,
  } = useAsyncFetch<LedgerLines>(fetchLedgerLines, {
    doNotFetchOnInit: !fetchLinesOnInit,
    default: initialLedgerLines,
    cache: true,
  });

  // If we don't have a ledgerId parameter, or it's invalid, use 'recent lines'.
  const activeLedger =
    ledgersOverview.ledgers.find((ld) => ld.id === ledgerId) || RECENT_LINES_LEDGER;

  React.useEffect(() => {
    if (!activeLedger.id) {
      return;
    }
    if (isEmpty(ledgerLines)) {
      // Initial load should fetch whatever page is in the url
      ledgerLinesFetch({ id: ledgerId, page: ledgerLinesPage + 1 });
    } else if (ledgerLines.ledgerId !== activeLedger.id) {
      // When the ID changes, fetch the first page. The call to setListQueryParams has already set page:0.
      ledgerLinesFetch({ id: ledgerId, page: 1 });
    } else if (ledgerLines.currentPage !== ledgerLinesPage + 1) {
      // Happens when paginating.
      ledgerLinesFetch({ id: ledgerId, page: ledgerLinesPage + 1 });
    }
  }, [activeLedger, ledgerLinesPage, ledgerId, ledgerLines, ledgerLinesFetch]);

  const recentLinesSelected = activeLedger === RECENT_LINES_LEDGER;
  const activeLines = recentLinesSelected
    ? ledgersOverview.recentLines
    : ledgerLines?.items || [];

  const selector = (
    <LedgerSelect
      activeLedger={activeLedger}
      ledgers={ledgersOverview.ledgers}
      onLedgerSelected={setLedgerId}
    />
  );

  return (
    <Page>
      <PageHeader title={t("payments.ledger_transactions")} back />
      <p>{t("payments.ledgers_intro")}</p>
      <AsyncContent loading={loading || false} error={error}>
        {() =>
          recentLinesSelected ? (
            <>
              {selector}
              <RecentLinesSubheader
                totalBalance={ledgersOverview.totalBalance}
                lifetimeSavings={ledgersOverview.lifetimeSavings}
              />
              <LedgerLinesTable
                ledgers={ledgersOverview.ledgers}
                lines={ledgersOverview.recentLines}
              />
              {isEmpty(ledgersOverview.recentLines) && (
                <p className="text-center">{t("payments.no_transaction_history")}</p>
              )}
            </>
          ) : (
            <>
              {selector}
              <LedgerLinesTable
                ledgers={ledgersOverview.ledgers}
                lines={activeLines}
                loading={ledgerLinesLoading}
                error={ledgerLinesError}
              />
              <div>
                {!isEmpty(activeLines) && (
                  <ForwardBackPagination
                    page={ledgerLinesPage}
                    pageCount={ledgerLines!.pageCount}
                    onPageChange={setLedgerLinesPage}
                    // scrollTop={140}
                  />
                )}
              </div>
            </>
          )
        }
      </AsyncContent>
    </Page>
  );
}

const RECENT_LINES_LEDGER = { kind: "recent-lines-ledger", id: 0 };
type RecentLinesLedger = typeof RECENT_LINES_LEDGER;

interface LedgerSelectProps {
  activeLedger: Ledger | RecentLinesLedger;
  ledgers: Ledger[];
  onLedgerSelected: (ledgerId: number) => void;
}

function LedgerSelect({ activeLedger, ledgers, onLedgerSelected }: LedgerSelectProps) {
  const showRecentLines = activeLedger === RECENT_LINES_LEDGER;
  const selectedLedgerLabel = showRecentLines
    ? r("payments.recent_ledger_lines")
    : r("payments.ledger_label", {
        amount: (activeLedger as Ledger).balance,
        label: (activeLedger as Ledger).contributionText,
      });
  return (
    <Select
      title={selectedLedgerLabel}
      value={"" + activeLedger.id}
      options={[
        { label: r("payments.recent_ledger_lines"), value: "0" },
        ...ledgers.map((led) => ({
          label: r("payments.ledger_label", {
            amount: led.balance,
            label: led.contributionText,
          }),
          value: "" + led.id,
        })),
      ]}
      onChange={(e) => onLedgerSelected(Number(e.target.value))}
    />
  );
}

function RecentLinesSubheader({
  totalBalance,
  lifetimeSavings,
}: {
  totalBalance?: Money;
  lifetimeSavings?: Money;
}) {
  return (
    <Stack row justify="between">
      <Stack col align="start">
        <h3>
          <Money>{totalBalance}</Money>
        </h3>
        <p>{t("payments.total_balance")}</p>
      </Stack>
      <Stack col align="end">
        <h3>
          <Money>{lifetimeSavings}</Money>
        </h3>
        <p>{t("payments.lifetime_savings")}</p>
      </Stack>
    </Stack>
  );
}

function LedgerLinesTable({
  ledgers,
  lines,
  loading,
  error,
}: {
  ledgers: Ledger[];
  lines: LedgerLine[];
  loading?: boolean;
  error?: any;
}) {
  const { selectedHashItem, selectHashItem, onHashItemSelected } = useHashSelector(
    lines,
    "opaqueId"
  );
  const feedback = error ? extractAppErrorAny(error) : null;
  return (
    <div className="position-relative">
      {loading && <IndeterminateLoader variant="content" />}
      <FormFeedback feedback={feedback} />
      <Table striped hover className={clsx(loading && "opacity-25")}>
        <tbody>
          {lines.map((line) => (
            <tr key={line.id}>
              <td>
                <Stack row justify="between">
                  <Stack col>
                    <a
                      className="ps-0"
                      href={`#${line.opaqueId}`}
                      onClick={(e) => onHashItemSelected(e, line)}
                    >
                      <strong>{dayjs(line.at).format("lll")}</strong>
                    </a>
                    <div>{line.memo}</div>
                  </Stack>
                  <Money
                    className={clsx(
                      line.amount.cents < 0 ? "color-danger" : "color-success"
                    )}
                  >
                    {line.amount}
                  </Money>
                </Stack>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
      <LedgerItemModal
        ledgers={ledgers}
        item={selectedHashItem}
        open={!!selectedHashItem}
        onClose={() => selectHashItem(null)}
      />
    </div>
  );
}

interface LedgerItemModalProps {
  ledgers: Ledger[];
  item?: LedgerLine | null;
  open: boolean;
  onClose: () => void;
}

function LedgerItemModal({ ledgers, item, open, onClose }: LedgerItemModalProps) {
  item = item || {
    id: 0,
    ledgerId: 0,
    opaqueId: "",
    at: "",
    memo: "",
    amount: { cents: 0, currency: "" },
    usageDetails: [],
  };
  const ledger = ledgers.find((led) => led.id === item.ledgerId);
  const dlgId = `transaction-${item.id}`;
  return (
    <Dialog open={open} onClose={onClose} labelledBy={dlgId}>
      <Card>
        <CardBody className="d-flex flex-column gap-3">
          <DialogHeader id={dlgId}>
            <Money
              className={clsx(item.amount.cents < 0 ? "color-danger" : "color-success")}
            >
              {item.amount}
            </Money>{" "}
            from {ledger?.contributionText}
          </DialogHeader>
          <CardText variant="title"></CardText>
          <CardText variant="text">
            {item.usageDetails.map(({ code, args }, i) => (
              <p key={i}>{t("ledgerusage." + code, { ...args })}</p>
            ))}
          </CardText>
          <Stack col gap={1}>
            <CardText variant="subtext">{dayjs(item.at).format("LLL")}</CardText>
            <CardText variant="subtext">
              {t("common.reference_id")}: {item.opaqueId}
            </CardText>
          </Stack>
          <Button variant="outline" onClick={onClose}>
            {t("common.close")}
          </Button>
        </CardBody>
      </Card>
    </Dialog>
  );
}
