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
import Button from "react-bootstrap/Button";
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

  React.useEffect(() => {
    if (!activeLedger || !ledgerIdParam) {
      return;
    }
    if (ledgerLines.currentPage !== page + 1) {
      // fetch onmount and when changing pages
      ledgerLinesFetch({ id: activeLedger.id, page: page + 1 });
    } else if (ledgerLines.ledgerId !== ledgerIdParam) {
      // fetch when selecting a ledger
      ledgerLinesFetch({ id: ledgerIdParam, page: 1 });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeLedger, page, ledgerIdParam]);

  const showRecentLines = hasRecentLines && !ledgerIdParam;
  const activeLines = showRecentLines
    ? ledgersOverview.recentLines
    : ledgerLines.items || [];

  if (ledgersOverviewLoading && ledgerLinesFetch) {
    return <PageLoader buffered />;
  }
  const noLedgerFound = ledgerIdParam && !activeLedger;
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
        showRecentLines={showRecentLines}
        ledgers={ledgersOverview.ledgers}
        // setting id to 0 means no active ledger and allows to show recent lines
        onLedgerSelected={(ledgerId) =>
          setListQueryParams({ page: 0 }, { ledger: ledgerId })
        }
      />
      <LedgerLines
        lines={activeLines}
        linesPage={ledgerLines.currentPage || 0}
        linesPageCount={ledgerLines.pageCount || 0}
        linesLoading={ledgersOverviewLoading || ledgerLinesLoading}
        hasMorePages={ledgerLines.hasMore}
        showRecentLines={showRecentLines}
        onLinesPageChange={(pg) => setListQueryParams({ page: pg })}
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
  hasMorePages,
  showRecentLines,
  onLinesPageChange,
}) => {
  const { selectedHashItem, onHashItemSelected } = useHashSelector(lines, "opaqueId");
  const withinPageCountLimits = linesPage >= 1 && linesPage <= linesPageCount;
  if (withinPageCountLimits && isEmpty(lines)) {
    return (
      <LayoutContainer className="text-center">{t("payments:no_money")}</LayoutContainer>
    );
  } else if (!withinPageCountLimits && !showRecentLines) {
    return (
      <LayoutContainer gutters className="text-center">
        <p className="mt-4">{t("payments:page_not_found")}</p>
        <Button variant="outline-primary btn-sm" onClick={() => onLinesPageChange(0)}>
          {t("payments:first_page")}
        </Button>
      </LayoutContainer>
    );
  }
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
        {!showRecentLines && (
          <ForwardBackPagination
            page={linesPage}
            pageCount={linesPageCount}
            hasMorePages={hasMorePages}
            onPageChange={onLinesPageChange}
            scrollTop={140}
          />
        )}
      </LayoutContainer>
      <LedgerItemModal
        item={selectedHashItem}
        onClose={() => onHashItemSelected(null, null)}
      />
    </div>
  );
};
