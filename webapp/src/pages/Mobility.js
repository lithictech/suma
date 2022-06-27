import Map from "../components/mobilitymap/Map";
import { t } from "../localization";
import React from "react";
import Container from "react-bootstrap/Container";

const Mobility = () => {
  return (
    <>
      <Container>
        <h5>{t("mobility:title")}</h5>
        <p className="text-secondary">{t("mobility:intro")}</p>
      </Container>
      <Map />
    </>
  );
};

export default Mobility;
