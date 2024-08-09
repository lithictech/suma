import api from "../api";
import AddFundsLinkButton from "../components/AddFundsLinkButton";
import ErrorScreen from "../components/ErrorScreen";
import ForwardBackPagination from "../components/ForwardBackPagination";
import LayoutContainer from "../components/LayoutContainer";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import LedgerItemModal from "../components/ledger/LedgerItemModal";
import { t } from "../localization";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useHashSelector from "../shared/react/useHashSelector";
import useListQueryControls from "../shared/react/useListQueryControls";
import clsx from "clsx";
import dayjs from "dayjs";
import find from "lodash/find";
import first from "lodash/first";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Dropdown from "react-bootstrap/Dropdown";
import Stack from "react-bootstrap/Stack";
import Table from "react-bootstrap/Table";

export default function LedgersOverview() {
  const { params, page, setListQueryParams } = useListQueryControls();
  const { state: ledgersOverview, loading: ledgersOverviewLoading } = useAsyncFetch(
    api.getLedgersOverview,
    {
      default: {},
      pickData: true,
    }
  );
  const {
    state: ledgerLines,
    loading: ledgerLinesLoading,
    asyncFetch: ledgerLinesFetch,
  } = useAsyncFetch(api.getLedgerLines, {
    default: {},
    pickData: true,
    doNotFetchOnInit: true,
  });
  const ledgerIdParam = Number(params.get("ledger"));
  const hasRecentLines = !isEmpty(ledgersOverview.recentLines);
  // when we have recent lines, we dont want an active ledger
  const firstLedger = hasRecentLines ? undefined : first(ledgersOverview.ledgers);
  const activeLedger = ledgerIdParam
    ? find(ledgersOverview.ledgers, { id: ledgerIdParam })
    : firstLedger;

  // Onmount or when we hit the 'back' button, we need to fetch lines
  // in case the page or ledger id changed.
  React.useEffect(() => {
    if (!activeLedger || !ledgerIdParam) {
      return;
    }
    if (ledgerLines.ledgerId !== ledgerIdParam) {
      ledgerLinesFetch({ id: ledgerIdParam, page: 1 });
    } else if (ledgerLines.currentPage !== page + 1) {
      ledgerLinesFetch({ id: activeLedger.id, page: page + 1 });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeLedger, page, ledgerIdParam]);

  const activeLines = activeLedger
    ? ledgerLines.items || []
    : ledgersOverview.recentLines;

  const handleLinesPageChange = (pg) => {
    setListQueryParams({ page: pg });
    ledgerLinesFetch({ id: activeLedger.id, page: pg + 1 });
  };

  const handleSelected = (ledgerId) => {
    // setting ledgerId to 0 signals that there is no active ledger
    // and allows to show recent lines
    setListQueryParams({ page: 0 }, { ledger: ledgerId });
    if (ledgerId && activeLedger?.id !== ledgerId) {
      ledgerLinesFetch({ id: ledgerId, page: 1 });
    }
  };

  if (ledgersOverviewLoading && ledgerLinesFetch) {
    return <PageLoader buffered />;
  }
  const noLedgerFound = ledgerIdParam && !activeLedger && isEmpty(ledgerLines);
  if (isEmpty(ledgersOverview.ledgers) || noLedgerFound) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  return (
    <>
      <LayoutContainer gutters top>
        <LinearBreadcrumbs back="/dashboard" />
        <h2 className="page-header">{t("payments:ledger_transactions")}</h2>
        <p>{t("payments:ledgers_intro")}</p>
      </LayoutContainer>
      <Header
        activeLedger={activeLedger}
        totalBalance={ledgersOverview.totalBalance}
        lifetimeSavings={ledgersOverview.lifetimeSavings}
        hasRecentLines={hasRecentLines}
        showRecentLines={hasRecentLines && !ledgerIdParam}
        ledgers={ledgersOverview.ledgers}
        onLedgerSelected={handleSelected}
      />
      <LedgerLines
        lines={activeLines}
        linesPage={page}
        linesPageCount={ledgerLines.pageCount || 0}
        linesLoading={ledgersOverviewLoading || ledgerLinesLoading}
        onLinesPageChange={handleLinesPageChange}
      />
    </>
  );
}

function Header({
  totalBalance,
  lifetimeSavings,
  activeLedger,
  ledgers,
  hasRecentLines,
  showRecentLines,
  onLedgerSelected,
}) {
  const selectedLedgerLabel = showRecentLines
    ? t("payments:recent_ledger_lines")
    : t("payments:ledger_label", {
        amount: activeLedger.balance,
        label: activeLedger.contributionText,
      });
  return (
    <LayoutContainer gutters>
      <div className="d-flex justify-content-between pb-2 align-items-start">
        <div>
          <h3>
            <Money>{totalBalance}</Money>
          </h3>
          <p className="m-0 mb-2">{t("payments:total_balance")}</p>
          <AddFundsLinkButton />
        </div>
        <div className="text-end">
          <h3>
            <Money>{lifetimeSavings}</Money>
          </h3>
          <p className="m-0">{t("payments:lifetime_savings")}</p>
        </div>
      </div>
      <Dropdown drop="down" className="mb-2">
        <Dropdown.Toggle
          className="w-100 dropdown-toggle-hide d-flex flex-row justify-content-between align-items-center"
          title={selectedLedgerLabel}
        >
          <Stack direction="horizontal" gap={2} className="overflow-hidden">
            {selectedLedgerLabel}
          </Stack>
          <div className="dropdown-toggle-manual"></div>
        </Dropdown.Toggle>
        <Dropdown.Menu className="w-100">
          {hasRecentLines && (
            <>
              <Dropdown.Item
                as={Stack}
                title={t("payments:recent_ledger_lines")}
                active={showRecentLines}
                className="overflow-hidden"
                onClick={() => onLedgerSelected(0)}
              >
                {t("payments:recent_ledger_lines")}
              </Dropdown.Item>
              <Dropdown.Divider />
            </>
          )}
          <Dropdown.Header>{t("payments:payment_title")}</Dropdown.Header>
          {ledgers.map((led) => (
            <Dropdown.Item
              key={led.id}
              as={Stack}
              title={led.contributionText}
              active={activeLedger?.id === led.id}
              className="overflow-hidden"
              onClick={() => onLedgerSelected(led.id)}
            >
              {t("payments:ledger_label", {
                amount: led.balance,
                label: led.contributionText,
              })}
            </Dropdown.Item>
          ))}
        </Dropdown.Menu>
      </Dropdown>
    </LayoutContainer>
  );
}

const LedgerLines = ({
  lines,
  linesPage,
  linesPageCount,
  linesLoading,
  onLinesPageChange,
}) => {
  const { selectedHashItem, onHashItemSelected } = useHashSelector(lines, "opaqueId");
  return (
    <div className="position-relative">
      {linesLoading && <PageLoader overlay />}
      <Table
        responsive
        striped
        hover
        className={clsx(
          "mt-1 table-flush table-borderless",
          linesLoading && "opacity-50"
        )}
      >
        <tbody>
          {lines.map((line) => (
            <tr key={line.id}>
              <td className="pt-3 pb-3">
                <div className="d-flex justify-content-between align-items-center gap-3 mb-1">
                  <div>
                    <a
                      className="ps-0"
                      href={`#${line.opaqueId}`}
                      onClick={(e) => onHashItemSelected(e, line)}
                    >
                      <strong>{dayjs(line.at).format("lll")}</strong>
                    </a>
                    <div>{line.memo}</div>
                  </div>
                  <Money
                    className={clsx(
                      line.amount.cents < 0 ? "text-danger" : "text-success"
                    )}
                  >
                    {line.amount}
                  </Money>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
      <LayoutContainer gutters>
        {!isEmpty(lines) ? (
          <ForwardBackPagination
            page={linesPage}
            pageCount={linesPageCount}
            onPageChange={onLinesPageChange}
            scrollTop={140}
          />
        ) : (
          <p className="text-center">{t("payments:no_money")}</p>
        )}
      </LayoutContainer>
      <LedgerItemModal
        item={selectedHashItem}
        onClose={() => onHashItemSelected(null, null)}
      />
    </div>
  );
};
