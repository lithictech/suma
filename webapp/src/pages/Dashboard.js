import api from "../api";
import scooterIcon from "../assets/images/kick-scooter.png";
import Header from "../components/Header";
import signOut from "../modules/signOut";
import { useUser } from "../state/useUser";
import React from "react";
import Badge from "react-bootstrap/Badge";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Navbar from "react-bootstrap/Navbar";
import Row from "react-bootstrap/Row";
import Table from "react-bootstrap/Table";
import { Link } from "react-router-dom";

const Dashboard = () => {
  const { user } = useUser();
  const [savingsBalance, setSavingsBalance] = React.useState("");
  const [accountBalance, setAccountBalance] = React.useState("");
  const [ledgers, setLedgers] = React.useState([]);

  React.useEffect(() => {
    api.dashboard().then((r) => {
      setSavingsBalance(r.data.lifetimeSavings.cents / 100.0);
      setAccountBalance(r.data.paymentAccountBalance.cents / 100.0);
      const getLast60Days = (ledgers) => {
        const now = new Date();
        const result = [];
        ledgers.forEach((ledger) => {
          const ledgerDate = new Date(ledger.at);
          const diffInTime = now.getTime() - ledgerDate.getTime();
          const diffInDays = diffInTime / (1000 * 3600 * 24);
          // only return ledgers dating 60 days or less from now
          if (diffInDays <= 60) {
            result.push(ledger);
          }
        });
        return result;
      };
      setLedgers(getLast60Days(r.data.ledgerLines));
    });
  }, []);
  return (
    <div className="mainContainer">
      <Header subText="Overview" />
      <Container>
        <Row>
          <Col className="px-3 py-4">
            {user.ongoingTrip && (
              <Link
                to="/map"
                className="btn btn-sm btn-success w-100 p-2 mb-4 rounded-pill"
              >
                You have an active ride in mobility map.
              </Link>
            )}
            <Row>
              <Col>
                <Link
                  to="/map"
                  className="btn btn-sm btn-light w-100 p-2 text-body rounded-pill border-2 border-darksuma"
                >
                  Scooter Service
                </Link>
              </Col>
              <Col>
                <Link
                  to="/map"
                  className="btn btn-sm btn-light w-100 p-2 text-body rounded-pill border-2 border-darksuma"
                >
                  Food Service
                </Link>
              </Col>
              <Col>
                <Link
                  to="/map"
                  className="btn btn-sm btn-light w-100 p-2 text-body rounded-pill border-2 border-darksuma"
                >
                  Other Services
                </Link>
              </Col>
            </Row>
          </Col>
        </Row>
        <Navbar bg="light" variant="light" className="justify-content-between p-3">
          <h6 className="m-0 text-secondary">
            Balance{" "}
            <Badge pill bg="secondary">
              ${accountBalance}
            </Badge>
          </h6>
          <h6 className="m-0 text-muted">
            Savings:{" "}
            <span>
              <Badge pill bg="secondary">
                ${savingsBalance}
              </Badge>
            </span>
          </h6>
        </Navbar>
        {ledgers ? (
          <Table
            responsive
            striped
            hover
            className="table-borderless align-middle text-body ledgerTable"
          >
            <thead>
              <tr>
                <th>Cost</th>
                <th className="w-50">Memo</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {ledgers.map((ledger, i) => {
                return (
                  <tr key={i}>
                    <td>
                      <Badge pill bg="darksuma">
                        ${ledger.amount.cents / 100.0}
                      </Badge>
                    </td>
                    <td title={ledger.memo}>
                      <span className="text-truncate d-block w-100">
                        <img
                          src={scooterIcon}
                          alt="scooter icon"
                          className="scooterIconWidth align-bottom"
                        />
                        {" " + ledger.memo}
                      </span>
                    </td>
                    <td
                      title={new Date(ledger.at).toLocaleDateString("en-us", {
                        weekday: "long",
                        year: "numeric",
                        month: "short",
                        day: "numeric",
                      })}
                    >
                      {new Date(ledger.at).toLocaleDateString("en-us", {
                        year: "2-digit",
                        month: "short",
                        day: "numeric",
                      })}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </Table>
        ) : (
          <p>No ledgers found.</p>
        )}
        <Button
          variant="danger"
          size="small"
          className="w-100 p-2 my-2 rounded-pill"
          onClick={signOut}
        >
          Log Out{" "}
          <i className="bi bi-box-arrow-in-right" role="img" aria-label="Map Icon"></i>
        </Button>
      </Container>
    </div>
  );
};

export default Dashboard;
