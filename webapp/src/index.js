import App from "./App";
import "./index.css";
import "./localization/i18n";
import "bootstrap/dist/css/bootstrap.min.css";
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/leaflet.markercluster";
import React from "react";
import ReactDOM from "react-dom";

ReactDOM.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
  document.getElementById("root")
);
