import Map from "../components/mobilitymap/Map";
import signOut from "../modules/signOut";
import { useUser } from "../state/useUser";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";

const Dashboard = () => {
  const { user } = useUser();
  return (
    <div className="mainContainer">
      <Row>
        <Col>
          <h2>Member Dashboard</h2>
          <p>Welcome back.</p>
          <p>{JSON.stringify(user)}</p>
          <Button>Food Service</Button>
          <Button>Scooter Service</Button>
          <Button>Bicycle Service</Button>
          <Map />
          <Button variant="danger" onClick={signOut}>
            Log Out
          </Button>
        </Col>
      </Row>
    </div>
  );
};

export default Dashboard;
