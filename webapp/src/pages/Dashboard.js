import signOut from "../modules/signOut";
import { useUser } from "../state/useUser";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import { Link } from "react-router-dom";

const Dashboard = () => {
  const { user } = useUser();
  return (
    <div className="mainContainer">
      <Row>
        <Col>
          <h2>Member Dashboard</h2>
          <p>Welcome back.</p>
          {user.ongoingTrip && 
          <Link to="/map" className="btn btn-sm btn-primary w-100">
            You have an ongoing trip 
          </Link>}
          <p>{JSON.stringify(user)}</p>
          <Link to="/map" className="btn btn-sm btn-success w-100">
          Scooter Service
          </Link>
          <Link to="/#todo" className="btn btn-sm btn-success w-100">
            Food Services
          </Link>
          <Link to="/#todo" className="btn btn-sm btn-success w-100">
            Other Services
          </Link>
          <Button variant="danger" className="w-100" onClick={signOut}>
            Log Out
          </Button>
        </Col>
      </Row>
    </div>
  );
};

export default Dashboard;
