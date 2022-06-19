import api from "../api";
import ForwardBackPagination from "../components/ForwardBackPagination";
import Money from "../components/Money";
import PageLoader from "../components/PageLoader";
import TopNav from "../components/TopNav";
import LedgerItemModal from "../components/ledger/LedgerItemModal";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useListQueryControls from "../shared/react/useListQueryControls";
import relativeUrl from "../shared/relativeUrl";
import setUrlPart from "../shared/setUrlPart";
import clsx from "clsx";
import dayjs from "dayjs";
import i18next from "i18next";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
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
    <div className="main-container">
      <TopNav />
      <Container>
        <p>{i18next.t("payments:ledgers_intro")}</p>
      </Container>
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
    </div>
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

  const handleLedgerLineSelected = (line) => {
    const hash = line ? line.opaqueId : "#";
    navigate(relativeUrl({ location: setUrlPart({ location, hash }) }));
    setSelectedLine(line);
  };

  return (
    <div>
      <Container>
        <h3>
          <Money>{ledger.balance}</Money>
        </h3>
        <p className="m-0">{i18next.t("payments:ledger_balance")}</p>
        <h5 className="mt-2">{i18next.t("payments:ledger_transactions")}</h5>
      </Container>
      {linesLoading && <PageLoader />}
      <Table
        responsive
        striped
        hover
        className={clsx("mt-2", linesLoading && "opacity-50")}
      >
        <tbody>
          {lines.map((line) => (
            <tr key={line.id}>
              <td>
                <div className="d-flex justify-content-between mb-1">
                  <Button
                    variant="link"
                    className="ps-0"
                    onClick={() => handleLedgerLineSelected(line)}
                  >
                    <strong>{dayjs(line.at).format("lll")}</strong>
                  </Button>
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
        onClose={() => handleLedgerLineSelected(null)}
      />
    </div>
  );
};
