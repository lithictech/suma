import api from "../api";
import Money from "../components/Money";
import TopNav from "../components/TopNav";
import LedgerItemModal from "../components/ledger/LedgerItemModal";
import useListQueryControls from "../shared/react/useListQueryControls";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode } from "../state/useError";
import clsx from "clsx";
import dayjs from "dayjs";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import Pagination from "react-bootstrap/Pagination";
import Table from "react-bootstrap/Table";
import { useLocation, useParams } from "react-router-dom";

const LedgerDetails = () => {
  const showLedgerModal = useToggle(false);

  const { id } = useParams();
  const { state } = useLocation();

  const { page, setPage, perPage, setPerPage } = useListQueryControls();
  const [pageCount, setPageCount] = React.useState(0);
  const [currentPage, setCurrentPage] = React.useState(1);
  const hasMore = useToggle(true);
  const [ledger, setLedger] = React.useState(null);
  const [ledgerItem, setLedgerItem] = React.useState({});
  const [ledgerLines, setLedgerLines] = React.useState([]);

  function handleLedgerItemLoad({ item }) {
    setLedgerItem(item);
    showLedgerModal.turnOn();
  }
  const handlePageChange = React.useCallback(
    ({ toPage }) => {
      setPage(toPage);
    },
    [setPage]
  );
  React.useEffect(() => {
    if (state && !ledger) {
      setLedger(state.firstLedger);
      setLedgerLines(state.firstLedger.lines);
      setPageCount(50); // TODO: Return from backend
    }
  }, [ledger, state, id]);
  React.useEffect(() => {
    // TODO: condition is causing multiple API reloads at once,
    // we need to refactor how we call the API when:
    // page loads and when *page* variable changes (see Pagination)
    if ((!state && !ledger) || currentPage !== page + 1) {
      api
        .getLedgerLines({ id: id, page: page + 1, perPage })
        .then((r) => {
          setLedger(r.data);
          setLedgerLines(r.data.items);
          setPageCount(r.data.pageCount || 2);
          setCurrentPage(r.data.currentPage);
          r.data.hasMore ? hasMore.turnOn() : hasMore.turnOff();
        })
        .catch((e) => {
          // TODO: display errors
          console.log(extractErrorCode(e));
        });
    }
  }, [currentPage, hasMore, id, state, ledger, page, perPage]);
  return (
    <div className="main-container">
      <TopNav />
      {/* TODO: add new loading image */}
      {!ledger && <p className="text-center m-3">Loading...</p>}
      {!_.isEmpty(ledgerLines) && (
        <>
          <div className="p-2 mb-4">
            <h4 className="m-0 text-secondary">{ledger.name}</h4>
            <p className="m-0">
              <Money className="fs-3">{ledger.balance}</Money>
            </p>
          </div>
          <CustomPagination
            page={page}
            pageCount={pageCount}
            hasMore={hasMore.isOn}
            onPageChange={({ toPage }) => handlePageChange({ toPage })}
          />
          <Table responsive striped hover className="table-borderless">
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
          </Table>
        </>
      )}
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
// and display page information e.g. Page 1 of 2 etc...
// check MUI pagination as ref
// Also, disable pagination buttons instead of conditional rendering
const CustomPagination = ({ page, pageCount, hasMore, onPageChange }) => {
  return (
    <Pagination size="sm" className="justify-content-end">
      {page !== 0 && (
        <Pagination.Prev onClick={(_e) => onPageChange({ toPage: page - 1 })}>
          &lsaquo; Prev
        </Pagination.Prev>
      )}
      {hasMore && (
        <Pagination.Next onClick={(_e) => onPageChange({ toPage: page + 1 })}>
          Next &rsaquo;
        </Pagination.Next>
      )}
    </Pagination>
  );
};
