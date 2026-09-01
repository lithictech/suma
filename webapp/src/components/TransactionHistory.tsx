import { IdParams } from "../api.ts";
import { t } from "../localization";
import { AppError } from "../modules/feedback.ts";
import useAsyncFetch from "../state/useAsyncFetch.ts";
import useHashSelector from "../state/useHashSelector.ts";
import IndeterminateLoader from "../ui/IndeterminateLoader.tsx";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
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
  params: URLSearchParams;
  page: number;
  ledgersOverview: LedgersView;
  getLedgerLines: (
    params: IdParams,
    cfg?: AxiosRequestConfig
  ) => Promise<AxiosResponse<LedgerLines>>;
  loading?: boolean;
  error?: AppError | null;
  ledgerId?: number;
}
export default function TransactionHistory({
  params,
  page,
  ledgersOverview,
  loading,
  error,
  ledgerId,
  getLedgerLines,
}: TransactionHistoryProps) {
  const fetchLedgerLines = React.useCallback(
    (data?: Record<string, any>) => getLedgerLines(data as IdParams),
    [getLedgerLines]
  );

  const {
    state: ledgerLines,
    loading: ledgerLinesLoading,
    asyncFetch: ledgerLinesFetch,
  } = useAsyncFetch<LedgerLines>(fetchLedgerLines, {
    default: {} as LedgerLines,
    doNotFetchOnInit: true,
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
      ledgerLinesFetch({ id: ledgerId, page: page + 1 });
    } else if (ledgerLines.ledgerId !== activeLedger.id) {
      // When the ID changes, fetch the first page. The call to setListQueryParams has already set page:0.
      ledgerLinesFetch({ id: ledgerId, page: 1 });
    } else if (ledgerLines.currentPage !== page + 1) {
      // Happens when paginating.
      ledgerLinesFetch({ id: ledgerId, page: page + 1 });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeLedger, page, ledgerId]);

  const recentLinesSelected = activeLedger === RECENT_LINES_LEDGER;
  const activeLines = recentLinesSelected
    ? ledgersOverview.recentLines
    : ledgerLines.items || [];

  const selector = (
    <LedgerSelect
      activeLedger={activeLedger}
      ledgers={ledgersOverview.ledgers}
      onLedgerSelected={(ledgerId: number) => console.log(ledgerId)}
      //   setListQueryParams({ page: 0 }, { ledger: ledgerId })
      // }
    />
  );

  return (
    <Page appNav>
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
                lines={ledgersOverview.recentLines}
                linesLoading={loading}
              />
              {isEmpty(ledgersOverview.recentLines) && (
                <p className="text-center">{t("payments.no_transaction_history")}</p>
              )}
            </>
          ) : (
            <>
              {/*<LedgerLinesTable*/}
              {/*  lines={activeLines}*/}
              {/*  linesLoading={ledgersOverviewLoading || ledgerLinesLoading}*/}
              {/*/>*/}
              {/*<div>*/}
              {/*  {!isEmpty(activeLines) && (*/}
              {/*    <ForwardBackPagination*/}
              {/*      page={page}*/}
              {/*      pageCount={ledgerLines.pageCount}*/}
              {/*      onPageChange={(pg) => setListQueryParams({ page: pg })}*/}
              {/*      scrollTop={140}*/}
              {/*    />*/}
              {/*  )}*/}
              {/*</div>*/}
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
  return null;
  // const showRecentLines = activeLedger === RECENT_LINES_LEDGER;
  // const selectedLedgerLabel = showRecentLines
  //   ? t("payments.recent_ledger_lines")
  //   : t("payments.ledger_label", {
  //       amount: activeLedger.balance,
  //       label: activeLedger.contributionText,
  //     });
  // return null;
  // return (
  //   <Dropdown drop="down" className="mb-2">
  //     <DropdownToggle
  //       className="w-100 dropdown-toggle-hide d-flex flex-row justify-content-between align-items-center"
  //       title={selectedLedgerLabel}
  //     >
  //       <Stack direction="horizontal" gap={2} className="overflow-hidden">
  //         {selectedLedgerLabel}
  //       </Stack>
  //       <div className="dropdown-toggle-manual"></div>
  //     </DropdownToggle>
  //     <DropdownMenu className="w-100">
  //       <DropdownItem
  //         as={Stack}
  //         title={t("payments.recent_ledger_lines")}
  //         active={showRecentLines}
  //         className="overflow-hidden"
  //         onClick={() => onLedgerSelected(0)}
  //       >
  //         {t("payments.recent_ledger_lines")}
  //       </DropdownItem>
  //       {ledgers.map((led) => (
  //         <DropdownItem
  //           key={led.id}
  //           as={Stack}
  //           title={led.contributionText}
  //           active={activeLedger.id === led.id}
  //           className="overflow-hidden"
  //           onClick={() => onLedgerSelected(led.id)}
  //         >
  //           {t("payments.ledger_label", {
  //             amount: led.balance,
  //             label: led.contributionText,
  //           })}
  //         </DropdownItem>
  //       ))}
  //     </DropdownMenu>
  //   </Dropdown>
  // );
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
  lines,
  linesLoading,
}: {
  lines: LedgerLine[];
  linesLoading?: boolean;
}) {
  const { selectedHashItem, onHashItemSelected } = useHashSelector(lines, "opaqueId");
  return (
    <div className="position-relative">
      {linesLoading && <IndeterminateLoader variant="content" />}
      <Table striped hover className={clsx(linesLoading && "opacity-50")}>
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
      {/*<LedgerItemModal*/}
      {/*  item={selectedHashItem}*/}
      {/*  onClose={() => onHashItemSelected(null, null)}*/}
      {/*/>*/}
    </div>
  );
}
