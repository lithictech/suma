import TopNav from "../components/TopNav";
import Map from "../components/mobilitymap/Map";
import i18next from "i18next";
import React from "react";

const MapPage = () => {
  return (
    <div className="main-container">
      <TopNav />
      <div className="mx-3">
        <h5>{i18next.t("title", { ns: "mobility" })}</h5>
        <p className="text-secondary">{i18next.t("intro", { ns: "mobility" })}</p>
      </div>
      <div>
        <Map />
      </div>
    </div>
  );
};

export default MapPage;
