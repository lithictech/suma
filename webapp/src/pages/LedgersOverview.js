import api from "../api";
import Money from "../components/Money";
import TopNav from "../components/TopNav";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import i18next from "i18next";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";
import Navbar from "react-bootstrap/Navbar";
import Spinner from "react-bootstrap/Spinner";
import Stack from "react-bootstrap/Stack";
import { useNavigate } from "react-router-dom";

const LedgersOverview = () => {
  const { state: dashboard, loading: dashboardLoading } = useAsyncFetch(api.ledgers, {
    default: {},
    pickData: true,
  });
  console.log(dashboard);
  return (
    <div className="main-container">
      <TopNav />
      <div className="mx-3">
        <h5>{i18next.t("ledgers_title", { ns: "dashboard" })}</h5>
        <p className="text-secondary">
          {i18next.t("ledgers_intro", { ns: "dashboard" })}
        </p>
      </div>
      <Container>
        {dashboardLoading ? (
          <Spinner animation="border" />
        ) : (
          <Overview dashboard={dashboard} />
        )}
      </Container>
    </div>
  );
};

export default LedgersOverview;

const Overview = ({ dashboard }) => {
  const navigate = useNavigate();
  const handleLedgerLoad = ({ ledger }) => {
    if (ledger.id === 1) {
      const firstLedger = _.merge(ledger, {
        lines: dashboard.singleLedgerLinesFirstPage,
      });
      navigate(`/ledger/${ledger.id}`, { state: { firstLedger: firstLedger } });
    } else {
      navigate(`/ledger/${ledger.id}`);
    }
  };
  return (
    <div className="px-2">
      <Navbar variant="light" className="justify-content-between py-3">
        <div>
          <h3>
            <Money>{dashboard.totalBalance}</Money>
          </h3>
          <p className="m-0">{i18next.t("total_account_balance", { ns: "dashboard" })}</p>
        </div>
      </Navbar>
      <hr />
      <h5 className="mt-3">{i18next.t("ledger_accounts", { ns: "dashboard" })}</h5>
      {dashboard.ledgers.map((ledger) => (
        <Button
          key={ledger}
          variant="primary"
          size="lg"
          className="my-2 w-100"
          onClick={() => handleLedgerLoad({ ledger: ledger })}
        >
          <Stack direction="horizontal" gap={3}>
            {ledger.name}
            <div className="ms-auto">
              <Money>{ledger.balance}</Money>
            </div>
          </Stack>
        </Button>
      ))}
    </div>
  );
};
