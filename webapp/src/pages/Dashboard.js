import api from "../api";
import AppNav from "../components/AppNav";
import Money from "../components/Money";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import { md, t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { useUser } from "../state/useUser";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import dayjs from "dayjs";
import _ from "lodash";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";
import Stack from "react-bootstrap/Stack";
import Table from "react-bootstrap/Table";
import { Link } from "react-router-dom";

const Dashboard = () => {
  const { user } = useUser();
  const { state: dashboard, loading: dashboardLoading } = useAsyncFetch(api.dashboard, {
    default: {},
    pickData: true,
  });

  return (
    <>
      {user.ongoingTrip && (
        <Alert variant="danger" className="border-radius-0">
          <p>{t("dashboard:check_ongoing_trip")}</p>
          <div className="d-flex justify-content-end">
            <Link to="/mobility" className="btn btn-sm btn-danger">
              {t("dashboard:check_ongoing_trip_button")}
              <i
                className="bi bi-box-arrow-in-right mx-1"
                role="img"
                aria-label="Map Icon"
              ></i>
            </Link>
          </div>
        </Alert>
      )}
      <AppNav />
      {dashboardLoading ? <PageLoader /> : <Ledger dashboard={dashboard} />}
    </>
  );
};

export default Dashboard;

const Ledger = ({ dashboard }) => {
  return (
    <>
      <LayoutContainer
        top="pt-2"
        gutters
        className="d-flex justify-content-between pb-2 align-items-start"
      >
        <div>
          <h3>
            <Money colored>{dashboard.paymentAccountBalance}</Money>
          </h3>
          <p className="m-0 mb-2">{t("dashboard:payment_account_balance")}</p>
          <Button variant="outline-success" href="/funding" as={RLink} size="sm">
            {t("payments:add_funds")}
          </Button>
        </div>
        <div className="text-end">
          <h3>
            <Money>{dashboard.lifetimeSavings}</Money>
          </h3>
          <p className="m-0">{t("dashboard:lifetime_savings")}</p>
        </div>
      </LayoutContainer>
      <hr />
      {!_.isEmpty(dashboard.ledgerLines) ? (
        <Table responsive striped hover className="table-borderless table-flush">
          <thead>
            <tr>
              <th>
                <Stack direction="horizontal" gap={3}>
                  {t("dashboard:recent_ledger_lines")}
                  <div className="ms-auto">
                    <Link to="/ledgers">{t("common:view_all")}</Link>
                  </div>
                </Stack>
              </th>
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
        <LayoutContainer top="pt-2" gutters>
          <p>{md("dashboard:no_money_md")}</p>
        </LayoutContainer>
      )}
    </>
  );
};
