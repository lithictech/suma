import Header from "../components/Header";
import signOut from "../modules/signOut";
import { useUser } from "../state/useUser";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import { Link } from "react-router-dom";

const Dashboard = () => {
  const { user } = useUser();
  return (
    <div className="mainContainer">
      <Header subText="Overview" />
      <Container>
        <Row>
          <Col className="px-3 py-4">
            {user.ongoingTrip && (
              <Link
                to="/map"
                className="btn btn-sm btn-success w-100 p-2 my-2 rounded-pill"
              >
                You have an active ride in mobility map.
              </Link>
            )}
            <Link
              to="/map"
              className="btn btn-sm btn-light w-100 p-2 my-2 text-body rounded-pill border border-primary"
            >
              Scooter Service
            </Link>
            <Link
              to="/map"
              className="btn btn-sm btn-light w-100 p-2 my-2 text-body rounded-pill border border-primary"
            >
              Food Service
            </Link>
            <Link
              to="/map"
              className="btn btn-sm btn-light w-100 p-2 my-2 text-body rounded-pill border border-primary"
            >
              Other Services
            </Link>
            <Button
              variant="danger"
              size="small"
              className="w-100 p-2 my-2 rounded-pill"
              onClick={signOut}
            >
              Log Out{" "}
              <i
                className="bi bi-box-arrow-in-right"
                role="img"
                aria-label="Map Icon"
              ></i>
            </Button>
          </Col>
        </Row>
      </Container>
    </div>
  );
};

export default Dashboard;
