import TopNav from "../components/TopNav";
import Map from "../components/mobilitymap/Map";
import { t } from "../localization";
import React from "react";
import Container from "react-bootstrap/Container";

const MapPage = () => {
  return (
    <div className="main-container">
      <TopNav />
      <Container>
        <h5>{t("mobility:title")}</h5>
        <p className="text-secondary">{t("mobility:intro")}</p>
      </Container>
      <div>
        <Map />
      </div>
    </div>
  );
};

export default MapPage;
