import Map from "../components/mobilitymap/Map";
import Header from "../components/Header"; 
import React from "react";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";
import Container from "react-bootstrap/Container";


const MapPage = () => {
  return (
    <div className="mainContainer">
      <Header subText="Transportation Service"/>
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
