import api from "../api";
import AddToHomescreen from "../components/AddToHomescreen";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import UnclaimedOrdersWidget from "../components/UnclaimedOrdersWidget";
import { md, t } from "../localization";
import readOnlyReason from "../modules/readOnlyReason";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { useUser } from "../state/useUser";
import { LayoutContainer } from "../state/withLayout";
import clsx from "clsx";
import dayjs from "dayjs";
import first from "lodash/first";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";
import Stack from "react-bootstrap/Stack";
import Table from "react-bootstrap/Table";
import { Link } from "react-router-dom";

export default function Dashboard() {
  const { user } = useUser();
  const { state: dashboard, loading: dashboardLoading } = useAsyncFetch(api.dashboard, {
    default: {},
    pickData: true,
  });
  const { availableOfferings, mobilityVehiclesAvailable } = dashboard;
  return (
    <>
      {user.ongoingTrip && (
        <Alert variant="danger" className="border-radius-0">
          <p>{t("dashboard:check_ongoing_trip")}</p>
          <div className="d-flex justify-content-end">
            <Link to="/mobility" className="btn btn-sm btn-danger px-3">
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
      {readOnlyReason(user, "read_only_unverified") && (
        <Alert variant="danger" className="border-radius-0">
          {readOnlyReason(user, "read_only_unverified")}
        </Alert>
      )}
      <AvailabilityLink
        label={t("dashboard:check_available_for_purchase")}
        iconClass="bi-bag"
        show={!isEmpty(availableOfferings)}
        to={
          availableOfferings?.length > 1
            ? "/food"
            : `/food/${first(availableOfferings)?.id}`
        }
      />
      <AvailabilityLink
        label={t("dashboard:get_rolling_with_discounts")}
        iconClass="bi-scooter"
        show={Boolean(mobilityVehiclesAvailable)}
        to="/mobility"
      />
      <AddToHomescreen />
      <UnclaimedOrdersWidget />
      {dashboardLoading ? <PageLoader /> : <Ledger dashboard={dashboard} />}
    </>
  );
}

function AvailabilityLink({ label, iconClass, show, to }) {
  if (!show) {
    return null;
  }
  return (
    <Alert variant="success" className="border-radius-0">
      <Alert.Link
        as={RLink}
        href={to}
        className="d-flex justify-content-between align-items-center text-success"
      >
        <i className={`bi ${iconClass} me-2`}></i>
        {label}
        <div className="ms-auto">
          <i className="bi bi-arrow-right ms-1"></i>
        </div>
      </Alert.Link>
    </Alert>
  );
}

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
      {!isEmpty(dashboard.ledgerLines) ? (
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
          <p>{md("dashboard:no_money")}</p>
        </LayoutContainer>
      )}
    </>
  );
};
