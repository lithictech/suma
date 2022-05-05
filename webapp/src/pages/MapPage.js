import Header from "../components/Header";
import Map from "../components/mobilitymap/Map";
import React from "react";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";

const MapPage = () => {
  return (
    <div className="mainContainer">
      <Header subText="Transportation Service" />
      <Container>
        <Row>
          <Col className="px-3 py-4">
            <Map />
          </Col>
        </Row>
      </Container>
    </div>
  );
};

export default MapPage;
