import api from "../api";
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
    cache: true,
  });
  const ledgerIdParam = Number(params.get("ledger")) || 0;

  // If we don't have a ledgerId parameter, or it's invalid, use 'recent lines'.
  let activeLedger;
  if (ledgerIdParam) {
    activeLedger = find(ledgersOverview.ledgers, { id: ledgerIdParam });
  }
  activeLedger = activeLedger || RECENT_LINES_LEDGER;

  React.useEffect(() => {
    if (!activeLedger.id) {
      return;
    }
    if (isEmpty(ledgerLines)) {
      // Initial load should fetch whatever page is in the url
      ledgerLinesFetch({ id: ledgerIdParam, page: page + 1 });
    } else if (ledgerLines.ledgerId !== activeLedger.id) {
      // When the ID changes, fetch the first page. The call to setListQueryParams has already set page:0.
      ledgerLinesFetch({ id: ledgerIdParam, page: 1 });
    } else if (ledgerLines.currentPage !== page + 1) {
      // Happens when paginating.
      ledgerLinesFetch({ id: ledgerIdParam, page: page + 1 });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeLedger, page, ledgerIdParam]);

  const recentLinesSelected = activeLedger === RECENT_LINES_LEDGER;
  const activeLines = recentLinesSelected
    ? ledgersOverview.recentLines
    : ledgerLines.items || [];

  if (ledgersOverviewLoading && ledgerLinesFetch) {
    return <PageLoader buffered />;
  }

  return (
    <>
      <LayoutContainer gutters top>
        <LinearBreadcrumbs back="/dashboard" />
        <h2 className="page-header">{t("payments:ledger_transactions")}</h2>
        <p>{t("payments:ledgers_intro")}</p>
        <LedgerSelect
          activeLedger={activeLedger}
          ledgers={ledgersOverview.ledgers}
          onLedgerSelected={(ledgerId) =>
            setListQueryParams({ page: 0 }, { ledger: ledgerId })
          }
        />
      </LayoutContainer>
      {recentLinesSelected ? (
        <>
          <LayoutContainer gutters>
            <RecentLinesSubheader
              totalBalance={ledgersOverview.totalBalance}
              lifetimeSavings={ledgersOverview.lifetimeSavings}
            />
          </LayoutContainer>
          <LedgerLinesTable
            lines={ledgersOverview.recentLines}
            linesLoading={ledgersOverviewLoading}
          />
        </>
      ) : (
        <>
          <LedgerLinesTable
            lines={activeLines}
            linesLoading={ledgersOverviewLoading || ledgerLinesLoading}
          />
          <LayoutContainer gutters>
            <ForwardBackPagination
              page={page}
              pageCount={ledgerLines.pageCount}
              onPageChange={(pg) => setListQueryParams({ page: pg })}
              scrollTop={140}
            />
          </LayoutContainer>
        </>
      )}
    </>
  );
}

// 'Fake' ledger we can use as the active ledger to indicate
// we should show recent lines instead.
const RECENT_LINES_LEDGER = { id: 0 };

function LedgerSelect({ activeLedger, ledgers, onLedgerSelected }) {
  const showRecentLines = activeLedger === RECENT_LINES_LEDGER;
  const selectedLedgerLabel = showRecentLines
    ? t("payments:recent_ledger_lines")
    : t("payments:ledger_label", {
        amount: activeLedger.balance,
        label: activeLedger.contributionText,
      });
  return (
    <Dropdown drop="down" className="mb-2">
      <Dropdown.Toggle
        className="w-100 dropdown-toggle-hide d-flex flex-row justify-content-between align-items-center"
        title={selectedLedgerLabel}
      >
        <Stack direction="horizontal" gap="2" className="overflow-hidden">
          {selectedLedgerLabel}
        </Stack>
        <div className="dropdown-toggle-manual"></div>
      </Dropdown.Toggle>
      <Dropdown.Menu className="w-100">
        <Dropdown.Item
          as={Stack}
          title={t("payments:recent_ledger_lines")}
          active={showRecentLines}
          className="overflow-hidden"
          onClick={() => onLedgerSelected(0)}
        >
          {t("payments:recent_ledger_lines")}
        </Dropdown.Item>
        {ledgers.map((led) => (
          <Dropdown.Item
            key={led.id}
            as={Stack}
            title={led.contributionText}
            active={activeLedger.id === led.id}
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
  );
}

function RecentLinesSubheader({ totalBalance, lifetimeSavings }) {
  return (
    <div className="d-flex justify-content-between align-items-start mt-3">
      <div>
        <h3>
          <Money>{totalBalance}</Money>
        </h3>
        <p className="m-0 mb-2">{t("payments:total_balance")}</p>
      </div>
      <div className="text-end">
        <h3>
          <Money>{lifetimeSavings}</Money>
        </h3>
        <p className="m-0">{t("payments:lifetime_savings")}</p>
      </div>
    </div>
  );
}

function LedgerLinesTable({ lines, linesLoading }) {
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
                    <div>
                      {line.id} {line.memo}
                    </div>
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
      <LedgerItemModal
        item={selectedHashItem}
        onClose={() => onHashItemSelected(null, null)}
      />
    </div>
  );
}
