import api from "../api";
import ForwardBackPagination from "../components/ForwardBackPagination";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import LedgerItemModal from "../components/ledger/LedgerItemModal";
import { t } from "../localization";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useHashSelector from "../shared/react/useHashSelector";
import useListQueryControls from "../shared/react/useListQueryControls";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import dayjs from "dayjs";
import first from "lodash/first";
import find from "lodash/find";
import React from "react";
import Container from "react-bootstrap/Container";
import Dropdown from "react-bootstrap/Dropdown";
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
  const firstLedger = first(ledgersOverview.ledgers);
  const activeLedger = ledgerIdParam
    ? find(ledgersOverview.ledgers, { id: ledgerIdParam })
    : firstLedger;

  //On mount (not page changes), fetch the ledger lines we aren't looking at
  // the 'first ledger items' (the active ledger must be the first ledger,
  // and the active page must be the first page).
  React.useEffect(() => {
    if (!activeLedger) {
      return;
    }
    if (activeLedger !== firstLedger) {
      ledgerLinesFetch({ id: activeLedger.id, page: page + 1 });
    } else if (page > 0) {
      ledgerLinesFetch({ id: firstLedger.id, page: page + 1 });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeLedger]);

  // When we hit the 'back' button, we need to re-fetch in case
  // the page or ledger id in the changed.
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

  const activeLines =
    ledgerLines.items ||
    (activeLedger === firstLedger ? ledgersOverview.firstLedgerLinesFirstPage : []);

  const handleLinesPageChange = (pg) => {
    setListQueryParams({ page: pg });
    ledgerLinesFetch({ id: activeLedger.id, page: pg + 1 });
  };

  const handleSelected = (led) => {
    setListQueryParams({ page: 0 }, { ledger: led.id });
    ledgerLinesFetch({ id: led.id, page: 1 });
  };

  return (
    <>
      <LayoutContainer gutters top>
        <LinearBreadcrumbs back="/dashboard" />
        <h2 className="page-header">{t("payments:ledger_transactions")}</h2>
        <p>{t("payments:ledgers_intro")}</p>
      </LayoutContainer>
      {ledgersOverview.ledgers ? (
        <>
          <Header
            activeLedger={activeLedger}
            totalBalance={ledgersOverview.totalBalance}
            ledgers={ledgersOverview.ledgers}
            onLedgerSelected={handleSelected}
          />
          <LedgerLines
            lines={activeLines}
            linesPage={page}
            linesPageCount={ledgerLines.pageCount || ledgersOverview.firstLedgerPageCount}
            linesLoading={ledgersOverviewLoading || ledgerLinesLoading}
            onLinesPageChange={handleLinesPageChange}
          />
        </>
      ) : (
        <PageLoader />
      )}
    </>
  );
}

function Header({ totalBalance, activeLedger, ledgers, onLedgerSelected }) {
  return (
    <LayoutContainer gutters>
      <h3>
        <Money>{totalBalance}</Money>
      </h3>
      <p>{t("payments:ledger_balance")}</p>
      <Dropdown drop="down" className="mb-2">
        <Dropdown.Toggle className="w-100 dropdown-toggle-hide d-flex flex-row justify-content-between align-items-center">
          <div className="d-flex flex-row justify-content-between flex-grow-1">
            <span className="d-block">{activeLedger.contributionText}</span>
            <Money className="d-block">{activeLedger.balance}</Money>
          </div>
          <div className="dropdown-toggle-manual"></div>
        </Dropdown.Toggle>
        <Dropdown.Menu align="end" className="w-100">
          {ledgers.map((led) => (
            <Dropdown.Item
              key={led.id}
              className="d-flex flex-row justify-content-between"
              onClick={() => onLedgerSelected(led)}
            >
              <div>{led.contributionText}</div>
              <div>
                <Money>{led.balance}</Money>
              </div>
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
    <>
      {linesLoading && <PageLoader />}
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
                <div className="d-flex justify-content-between mb-1">
                  <a
                    className="ps-0"
                    href={`#${line.opaqueId}`}
                    onClick={(e) => onHashItemSelected(e, line)}
                  >
                    <strong>{dayjs(line.at).format("lll")}</strong>
                  </a>
                  <Money
                    className={clsx(
                      line.amount.cents < 0 ? "text-danger" : "text-success"
                    )}
                  >
                    {line.amount}
                  </Money>
                </div>
                <div>{line.memo}</div>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
      <Container>
        <ForwardBackPagination
          page={linesPage}
          pageCount={linesPageCount}
          onPageChange={onLinesPageChange}
          scrollTop={140}
        />
      </Container>
      <LedgerItemModal
        item={selectedHashItem}
        onClose={() => onHashItemSelected(null, null)}
      />
    </>
  );
};
