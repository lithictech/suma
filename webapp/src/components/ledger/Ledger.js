import useToggle from "../../shared/react/useToggle";
import Money from "../Money";
import clsx from "clsx";
import dayjs from "dayjs";
import i18next from "i18next";
import _ from "lodash";
import React from "react";
import Navbar from "react-bootstrap/Navbar";
import Table from "react-bootstrap/Table";
import { Link } from "react-router-dom";
import LedgerDetails from "./LedgerDetails";

const Ledger = ({ dashboard }) => {
  const ledgerModalOpen = useToggle(false);
  const [ledgerDetails, setLedgerDetails] = React.useState({});
  const ledgerLoading = useToggle(false);
  const handleLedgerLoad = ({ ledgerId }) => {
    ledgerModalOpen.toggle();
    ledgerLoading.turnOn();
    // TODO: replace promise with new ledger API and pass ledgerId param
    Promise.resolve({
      ledgerId,
      memo: "Suma Mobility - Spin E-Scooters",
      amount: { cents: -130, currency: "USD" },
      createdAt: "2022-07-03T18:26:19.170+00:00",
      mobility: {
        startedAt: "2022-06-03T18:26:19.170+00:00",
        endedAt: "2022-06-03T18:28:19.170+00:00",
      },
    }).then((r) => {
      // TODO: remove setTimeout when using new ledger API
      setTimeout(() => {
        ledgerLoading.turnOff();
      }, 1000);
      setLedgerDetails(r);
    });
  };
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
                    {/* TODO: setup replace hardcoded "1" with ledger id variable */}
                    <Link to="#" onClick={() => handleLedgerLoad({ ledgerId: "1" })}>
                      <strong>{dayjs(ledger.at).format("lll")}</strong>
                    </Link>
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
      <LedgerDetails
        ledger={ledgerDetails}
        isLoading={ledgerLoading.isOn}
        show={ledgerModalOpen.isOn}
        onClose={ledgerModalOpen.turnOff}
        onExited={ledgerLoading.turnOff}
      />
    </>
  );
};

export default Ledger;
