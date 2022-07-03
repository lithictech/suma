import api from "../api";
import ForwardBackPagination from "../components/ForwardBackPagination";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import Money from "../components/Money";
import PageLoader from "../components/PageLoader";
import LedgerItemModal from "../components/ledger/LedgerItemModal";
import { t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import relativeUrl from "../shared/relativeUrl";
import setUrlPart from "../shared/setUrlPart";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import dayjs from "dayjs";
import _ from "lodash";
import React from "react";
import Container from "react-bootstrap/Container";
import Table from "react-bootstrap/Table";
import { useLocation, useNavigate } from "react-router-dom";

export default function LedgersOverview() {
  const { page, setPage } = useListQueryControls();
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

  const ledger = _.first(ledgersOverview.ledgers);

  React.useEffect(() => {
    if (ledger && page > 1) {
      ledgerLinesFetch({ id: ledger.id, page });
    }
    // Only run this on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ledger]);

  const handleLinesPageChange = (pg) => {
    setPage(pg);
    ledgerLinesFetch({ id: ledger.id, page: pg });
  };
  return (
    <>
      <LayoutContainer gutters top>
        <LinearBreadcrumbs />
        <h2 className="page-header">{t("payments:ledger_transactions")}</h2>
        <p>{t("payments:ledgers_intro")}</p>
      </LayoutContainer>
      {ledgersOverview.ledgers ? (
        <Ledger
          ledger={ledger}
          lines={ledgerLines.items || ledgersOverview.singleLedgerLinesFirstPage}
          linesPage={page}
          linesPageCount={ledgerLines.pageCount || ledgersOverview.singleLedgerPageCount}
          linesLoading={ledgersOverviewLoading || ledgerLinesLoading}
          onLinesPageChange={handleLinesPageChange}
        />
      ) : (
        <PageLoader />
      )}
    </>
  );
}

const Ledger = ({
  ledger,
  lines,
  linesPage,
  linesPageCount,
  linesLoading,
  onLinesPageChange,
}) => {
  const navigate = useNavigate();
  const location = useLocation();
  const [selectedLine, setSelectedLine] = React.useState(null);
  React.useEffect(() => {
    if (!location.hash) {
      return;
    }
    const line = _.find(lines, { opaqueId: _.trimStart(location.hash, "#") });
    if (!line) {
      return;
    }
    setSelectedLine(line);
  }, [location, lines]);

  const handleLedgerLineSelected = (event, line) => {
    event && event.preventDefault();
    const hash = line ? line.opaqueId : "#";
    navigate(relativeUrl({ location: setUrlPart({ location, hash }) }));
    setSelectedLine(line);
  };

  return (
    <>
      <LayoutContainer gutters>
        <h3>
          <Money>{ledger.balance}</Money>
        </h3>
        <p>{t("payments:ledger_balance")}</p>
      </LayoutContainer>
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
                    onClick={(e) => handleLedgerLineSelected(e, line)}
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
        item={selectedLine}
        onClose={() => handleLedgerLineSelected(null, null)}
      />
    </>
  );
};
