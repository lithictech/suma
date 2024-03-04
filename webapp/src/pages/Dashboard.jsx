import api from "../api";
import AddFundsLinkButton from "../components/AddFundsLinkButton";
import AddToHomescreen from "../components/AddToHomescreen";
import LayoutContainer from "../components/LayoutContainer";
import NavButton from "../components/NavButton";
import PageLoader from "../components/PageLoader";
import SeeAlsoAlert from "../components/SeeAlsoAlert";
import { t } from "../localization";
import readOnlyReason from "../modules/readOnlyReason";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useUser from "../state/useUser";
import clsx from "clsx";
import dayjs from "dayjs";
import first from "lodash/first";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Stack from "react-bootstrap/Stack";
import Table from "react-bootstrap/Table";
import { Link } from "react-router-dom";

export default function Dashboard() {
  const { user } = useUser();
  const { state: dashboard, loading: dashboardLoading } = useAsyncFetch(api.dashboard, {
    default: {},
    pickData: true,
  });
  const { offerings, mobilityVehiclesAvailable } = dashboard;
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
      {user.unclaimedOrdersCount === 0 ? (
        <>
          <SeeAlsoAlert
            variant="info"
            textVariant="muted"
            label={t("dashboard:check_available_for_purchase")}
            alertClass={Boolean(mobilityVehiclesAvailable) && "mb-0"}
            iconClass="bi-bag-fill"
            show={!isEmpty(offerings)}
            to={offerings?.length > 1 ? "/food" : `/food/${first(offerings)?.id}`}
          />
          <SeeAlsoAlert
            variant="info"
            textVariant="muted"
            label={t("dashboard:get_rolling_with_discounts")}
            iconClass="bi-scooter"
            show={Boolean(mobilityVehiclesAvailable)}
            to="/mobility"
          />
        </>
      ) : (
        <SeeAlsoAlert
          alertClass="blinking-alert"
          variant="success"
          label={t("dashboard:claim_orders")}
          iconClass="bi-bag-check-fill"
          show
          to="/unclaimed-orders"
        />
      )}
      <LayoutContainer gutters>
        <AddToHomescreen />
      </LayoutContainer>
      {dashboardLoading ? <PageLoader buffered /> : <Ledger dashboard={dashboard} />}
    </>
  );
}

const Ledger = ({ dashboard }) => {
  return (
    <>
      <LayoutContainer top gutters>
        <div className="d-flex justify-content-between pb-2 align-items-start">
          <div>
            <h3>
              <Money colored>{dashboard.paymentAccountBalance}</Money>
            </h3>
            <p className="m-0 mb-2">{t("dashboard:payment_account_balance")}</p>
            <AddFundsLinkButton />
          </div>
          <div className="text-end">
            <h3>
              <Money>{dashboard.lifetimeSavings}</Money>
            </h3>
            <p className="m-0">{t("dashboard:lifetime_savings")}</p>
          </div>
        </div>
      </LayoutContainer>
      <hr />
      <Table responsive striped hover className="table-borderless table-flush">
        <thead>
          <tr>
            <th>
              <Stack direction="horizontal" gap={3}>
                {t("dashboard:recent_ledger_lines")}
                <div className="ms-auto">
                  <NavButton right href="/ledgers" size="sm" className="nowrap">
                    {t("common:view_all")}
                  </NavButton>
                </div>
              </Stack>
            </th>
          </tr>
        </thead>
        <tbody>
          {dashboard.ledgerLines.map((ledger, i) => (
            <tr key={i}>
              <td>
                <div className="d-flex justify-content-between align-items-center gap-3 mb-1">
                  <div>
                    <strong>{dayjs(ledger.at).format("lll")}</strong>
                    <div>{ledger.memo}</div>
                  </div>
                  <Money
                    className={clsx(
                      ledger.amount.cents < 0 ? "text-danger" : "text-success"
                    )}
                  >
                    {ledger.amount}
                  </Money>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
      {isEmpty(dashboard.ledgerLines) && (
        <>
          <p className="text-center">{t("dashboard:no_money")}</p>
          <AddFundsLinkButton />
        </>
      )}
    </>
  );
};
