import Map from "../components/mobilitymap/Map";
import { useUser } from "../state/useUser";
import React from "react";
// import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";

const MapPage = () => {
  const { user } = useUser();
  return (
    <div className="mainContainer">
      <Row>
        <Col>
          <h2>Mobility Map</h2>
          <p>{JSON.stringify(user.phone)}</p>
          <Map />
        </Col>
      </Row>
    </div>
  );
};

export default MapPage;
