import api from "../api";
import Money from "../components/Money";
import TopNav from "../components/TopNav";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { useUser } from "../state/useUser";
import clsx from "clsx";
import dayjs from "dayjs";
import i18next from "i18next";
import _ from "lodash";
import React from "react";
import { Alert } from "react-bootstrap";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Navbar from "react-bootstrap/Navbar";
import Row from "react-bootstrap/Row";
import Spinner from "react-bootstrap/Spinner";
import Table from "react-bootstrap/Table";
import { Link } from "react-router-dom";

const Dashboard = () => {
  const { user } = useUser();
  const { state: dashboard, loading: dashboardLoading } = useAsyncFetch(api.dashboard, {
    default: {},
    pickData: true,
  });

  return (
    <div className="main-container">
      <TopNav />
      <Container>
        <Row>
          <Col className="px-3 py-2">
            {user.ongoingTrip && (
              <Alert variant="danger">
                <p>{i18next.t("check_ongoing_trip", { ns: "dashboard" })}</p>
                <div className="d-flex justify-content-end">
                  <Link to="/map" className="btn btn-sm btn-danger">
                    {i18next.t("check_ongoing_trip_button", { ns: "dashboard" })}
                    <i
                      className="bi bi-box-arrow-in-right mx-1"
                      role="img"
                      aria-label="Map Icon"
                    ></i>
                  </Link>
                </div>
              </Alert>
            )}
            <Row>
              <Col>
                <AppLink to="/map" label="Mobility" />
              </Col>
              <Col>
                <AppLink to="#todo" label="Food" />
              </Col>
              <Col>
                <AppLink to="/map" label="Utilities" />
              </Col>
            </Row>
          </Col>
        </Row>
        {dashboardLoading ? (
          <Spinner animation="border" />
        ) : (
          <Ledger dashboard={dashboard} />
        )}
      </Container>
    </div>
  );
};

export default Dashboard;

const AppLink = ({ to, label }) => {
  return (
    <Link to={to} className="btn btn-sm btn-primary w-100 p-2 text-body rounded-pill">
      {label}
    </Link>
  );
};

const Ledger = ({ dashboard }) => {
  return (
    <>
      <Navbar variant="light" className="justify-content-between py-3 px-2">
        <div>
          <h3>
            <Money colored>{dashboard.paymentAccountBalance}</Money>
          </h3>
          <p className="m-0">
            {i18next.t("payment_account_balance", { ns: "dashboard" })}
          </p>
        </div>
        <div className="text-end">
          <h3>
            <Money>{dashboard.lifetimeSavings}</Money>
          </h3>
          <p className="m-0">{i18next.t("lifetime_savings", { ns: "dashboard" })}</p>
        </div>
      </Navbar>
      <hr />
      {!_.isEmpty(dashboard.ledgerLines) ? (
        <Table responsive striped hover className="table-borderless">
          <thead>
            <tr>
              <th>{i18next.t("recent_ledger_lines", { ns: "dashboard" })}</th>
            </tr>
          </thead>
          <tbody>
            {dashboard.ledgerLines.map((ledger, i) => (
              <tr key={i}>
                <td>
                  <div className="d-flex justify-content-between mb-1">
                    <strong>{dayjs(ledger.at).format("lll")}</strong>
                    <Money
                      className={clsx(
                        ledger.amount.cents < 0 ? "text-danger" : "text-success"
                      )}
                    >
                      {ledger.amount}
                    </Money>
                  </div>
                  <div>{ledger.memo}</div>
                </td>
              </tr>
            ))}
          </tbody>
        </Table>
      ) : (
        <p>
          You haven&rsquo;t added or spent any money.{" "}
          <Link to="/#todo">Press here to add money to your account</Link>.
        </p>
      )}
    </>
  );
};
