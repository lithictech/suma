import React from "react";

import Button from 'react-bootstrap/Button';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';
import Col from 'react-bootstrap/Col';

const Dashboard = () => {
  return (
    <Container>
      <Row className="justify-content-center">
        <Col>
          <h2>Member Dashboard</h2>
          <p>Welcome back.</p>
          <Button>Food Service</Button>
          <Button>Scooter Service</Button>
          <Button>Bicycle Service</Button>
        </Col>
      </Row>
    </Container>
  );
}

export default Dashboard;
