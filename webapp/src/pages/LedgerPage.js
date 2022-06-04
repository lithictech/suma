import api from "../api";
import TopNav from "../components/TopNav";
import Ledger from "../components/ledger/Ledger";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import i18next from "i18next";
import React from "react";
import Container from "react-bootstrap/Container";
import Spinner from "react-bootstrap/Spinner";

const LedgerPage = () => {
  const { state: dashboard, loading: dashboardLoading } = useAsyncFetch(api.dashboard, {
    default: {},
    pickData: true,
  });

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
          <Ledger dashboard={dashboard} />
        )}
      </Container>
    </div>
  );
};

export default LedgerPage;
