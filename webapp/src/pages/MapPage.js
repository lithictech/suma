import TopNav from "../components/TopNav";
import Map from "../components/mobilitymap/Map";
import i18next from "i18next";
import React from "react";
import Container from "react-bootstrap/Container";

const MapPage = () => {
  return (
    <div className="main-container">
      <TopNav />
      <Container>
        <h5>{i18next.t("title", { ns: "mobility" })}</h5>
        <p className="text-secondary">{i18next.t("intro", { ns: "mobility" })}</p>
      </Container>
      <div>
        <Map />
      </div>
    </div>
  );
};

export default MapPage;
