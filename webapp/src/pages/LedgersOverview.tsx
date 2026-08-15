import api from "../api";
import BackBreadcrumb from "../components/BackBreadcrumb";
import ForwardBackPagination from "../components/ForwardBackPagination";
import LayoutContainer from "../components/LayoutContainer";
import PageHeading from "../components/PageHeading";
import PageLoader from "../components/PageLoader";
import LedgerItemModal from "../components/ledger/LedgerItemModal";
import { t } from "../localization";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useHashSelector from "../shared/react/useHashSelector";
import useListQueryControls from "../shared/react/useListQueryControls";
import Dropdown from "../ui/Dropdown";
import DropdownItem from "../ui/DropdownItem";
import DropdownMenu from "../ui/DropdownMenu";
import DropdownToggle from "../ui/DropdownToggle";
import Stack from "../ui/Stack";
import Table from "../ui/Table";
import clsx from "clsx";
import dayjs from "dayjs";
import find from "lodash/find";
import isEmpty from "lodash/isEmpty";
import React from "react";

export default function LedgersOverview() {
  const { params, page, setListQueryParams } = useListQueryControls();
  const { state: ledgersOverview, loading: ledgersOverviewLoading } =
    useAsyncFetch<LedgersView>(api.getLedgersOverview, {
      default: {} as LedgersView,
      pickData: true,
    });
  const {
    state: ledgerLines,
    loading: ledgerLinesLoading,
    asyncFetch: ledgerLinesFetch,
  } = useAsyncFetch<LedgerLines>(api.getLedgerLines, {
    default: {} as LedgerLines,
    pickData: true,
    doNotFetchOnInit: true,
    cache: true,
  });
  const ledgerIdParam = Number(params.get("ledger")) || 0;

  // If we don't have a ledgerId parameter, or it's invalid, use 'recent lines'.
  let activeLedger: Ledger | undefined;
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
        <BackBreadcrumb back="/dashboard" />
        <PageHeading>{t("payments.ledger_transactions")}</PageHeading>
        <p>{t("payments.ledgers_intro")}</p>
        <LedgerSelect
          activeLedger={activeLedger}
          ledgers={ledgersOverview.ledgers}
          onLedgerSelected={(ledgerId: number) =>
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
          {isEmpty(ledgersOverview.recentLines) && (
            <p className="text-center">{t("payments.no_transaction_history")}</p>
          )}
        </>
      ) : (
        <>
          <LedgerLinesTable
            lines={activeLines}
            linesLoading={ledgersOverviewLoading || ledgerLinesLoading}
          />
          <LayoutContainer gutters>
            {!isEmpty(activeLines) && (
              <ForwardBackPagination
                page={page}
                pageCount={ledgerLines.pageCount}
                onPageChange={(pg) => setListQueryParams({ page: pg })}
                scrollTop={140}
              />
            )}
          </LayoutContainer>
        </>
      )}
    </>
  );
}

// 'Fake' ledger we can use as the active ledger to indicate
// we should show recent lines instead.
const RECENT_LINES_LEDGER = { id: 0 } as Ledger;

interface LedgerSelectProps {
  activeLedger: Ledger;
  ledgers: Ledger[];
  onLedgerSelected: (ledgerId: number) => void;
}

function LedgerSelect({ activeLedger, ledgers, onLedgerSelected }: LedgerSelectProps) {
  const showRecentLines = activeLedger === RECENT_LINES_LEDGER;
  const selectedLedgerLabel = showRecentLines
    ? t("payments.recent_ledger_lines")
    : t("payments.ledger_label", {
        amount: activeLedger.balance,
        label: activeLedger.contributionText,
      });
  return (
    <Dropdown drop="down" className="mb-2">
      <DropdownToggle
        className="w-100 dropdown-toggle-hide d-flex flex-row justify-content-between align-items-center"
        title={selectedLedgerLabel}
      >
        <Stack direction="horizontal" gap={2} className="overflow-hidden">
          {selectedLedgerLabel}
        </Stack>
        <div className="dropdown-toggle-manual"></div>
      </DropdownToggle>
      <DropdownMenu className="w-100">
        <DropdownItem
          as={Stack}
          title={t("payments.recent_ledger_lines")}
          active={showRecentLines}
          className="overflow-hidden"
          onClick={() => onLedgerSelected(0)}
        >
          {t("payments.recent_ledger_lines")}
        </DropdownItem>
        {ledgers.map((led) => (
          <DropdownItem
            key={led.id}
            as={Stack}
            title={led.contributionText}
            active={activeLedger.id === led.id}
            className="overflow-hidden"
            onClick={() => onLedgerSelected(led.id)}
          >
            {t("payments.ledger_label", {
              amount: led.balance,
              label: led.contributionText,
            })}
          </DropdownItem>
        ))}
      </DropdownMenu>
    </Dropdown>
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
    <div className="d-flex justify-content-between align-items-start mt-3">
      <div>
        <h3>
          <Money>{totalBalance}</Money>
        </h3>
        <p className="m-0 mb-2">{t("payments.total_balance")}</p>
      </div>
      <div className="text-end">
        <h3>
          <Money>{lifetimeSavings}</Money>
        </h3>
        <p className="m-0">{t("payments.lifetime_savings")}</p>
      </div>
    </div>
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
      <LedgerItemModal
        item={selectedHashItem}
        onClose={() => onHashItemSelected(null, null)}
      />
    </div>
  );
}
