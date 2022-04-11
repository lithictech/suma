import signOut from "../modules/signOut";
import { useUser } from "../state/useUser";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Map from "../components/mobilitymap/Map";

const Dashboard = () => {
  const { user } = useUser();
  return (
    <Container>
      <Row className="justify-content-center">
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
    </Container>
  );
};

export default Dashboard;
