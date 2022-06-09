import api from "../api";
import FormError from "../components/FormError";
import Money from "../components/Money";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import TopNav from "../components/TopNav";
import LedgerItemModal from "../components/ledger/LedgerItemModal";
import useListQueryControls from "../shared/react/useListQueryControls";
import useToggle from "../shared/react/useToggle";
import { useError } from "../state/useError";
import clsx from "clsx";
import dayjs from "dayjs";
import i18next from "i18next";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import Pagination from "react-bootstrap/Pagination";
import Table from "react-bootstrap/Table";
import { useLocation, useNavigate, useParams } from "react-router-dom";

const LedgerDetails = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const { state } = useLocation();
  const firstLedgerLines = state ? state.firstLedgerLines : undefined;
  const { page, setPage, perPage, setPerPage } = useListQueryControls();

  const showLedgerModal = useToggle(false);
  const [pageCount, setPageCount] = React.useState(0);
  const [currentPage, setCurrentPage] = React.useState(0);
  const [ledgerItem, setLedgerItem] = React.useState({});
  const [ledgerLines, setLedgerLines] = React.useState([]);
  const [error, setError] = useError();
  const hasMore = useToggle(true);
  const ledgerLoading = useToggle(false);

  function handleLedgerItemLoad({ item }) {
    setLedgerItem(item);
    showLedgerModal.turnOn();
  }
  const handlePageChange = React.useCallback(
    ({ toPage }) => {
      setPage(toPage);
      setLedgerLines([]);
    },
    [setPage]
  );
  React.useEffect(() => {
    if (firstLedgerLines) {
      setLedgerLines(firstLedgerLines);
      setPageCount(50); // TODO: Return from backend
    }
  }, [firstLedgerLines]);
  React.useEffect(() => {
    if (!firstLedgerLines && _.isEmpty(ledgerLines) && !error) {
      api
        .getLedgerLines({ id: id, page: page + 1, perPage })
        .then((r) => {
          const ledger = r.data;
          if (ledger.currentPage > ledger.pageCount) {
            setPage(0);
          } else {
            setLedgerLines(ledger.items);
            setPageCount(ledger.pageCount || 2);
            setCurrentPage(ledger.currentPage);
            ledger.hasMore ? hasMore.turnOn() : hasMore.turnOff();
          }
        })
        .catch(() => {
          setError("unhandled_error");
          setLedgerLines([]);
        });
    }
  }, [
    id,
    ledgerLines,
    page,
    perPage,
    setPage,
    hasMore,
    firstLedgerLines,
    error,
    setError,
    navigate,
  ]);
  return (
    <div className="main-container">
      <TopNav />
      <Button variant="primary my-2" href="/ledgers-overview" as={RLink}>
        <i className="bi bi-chevron-left"></i> {i18next.t("back", { ns: "common" })}
      </Button>
      <Table responsive striped hover className="mt-2">
        <thead>
          <tr>
            <th>{i18next.t("all_ledger_lines", { ns: "dashboard" })}</th>
          </tr>
        </thead>
        {!_.isEmpty(ledgerLines) && !ledgerLoading.isOn && (
          <tbody>
            {ledgerLines.map((line) => (
              <tr key={line.id}>
                <td>
                  <div className="d-flex justify-content-between mb-1">
                    <Button
                      variant="link"
                      onClick={() => handleLedgerItemLoad({ item: line })}
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
        )}
      </Table>
      {!_.isEmpty(ledgerLines) && (
        <CustomPagination
          page={page}
          pageCount={pageCount}
          hasMore={hasMore.isOn}
          onPageChange={({ toPage }) => handlePageChange({ toPage })}
        />
      )}
      <PageLoader show={_.isEmpty(ledgerLines) && !error} />
      <FormError error={error} />
      <LedgerItemModal
        item={ledgerItem}
        show={showLedgerModal.isOn}
        onClose={showLedgerModal.turnOff}
      />
    </div>
  );
};

export default LedgerDetails;

// TODO: finish pagination, needs setPerPage dropdown menu
// and display page information e.g. Page 1 of 2 etc,
// use MUI pagination as ref
const CustomPagination = ({ page, hasMore, onPageChange }) => {
  return (
    <Pagination size="sm" className="justify-content-end">
      <Pagination.Prev
        className={clsx(page === 0 ? "disabled" : null)}
        onClick={(_e) => onPageChange({ toPage: page - 1 })}
      >
        &lsaquo; {i18next.t("pagination_prev", { ns: "dashboard" })}
      </Pagination.Prev>
      <Pagination.Next
        className={clsx(!hasMore ? "disabled" : null)}
        onClick={(_e) => onPageChange({ toPage: page + 1 })}
      >
        {i18next.t("pagination_next", { ns: "dashboard" })} &rsaquo;
      </Pagination.Next>
    </Pagination>
  );
};
