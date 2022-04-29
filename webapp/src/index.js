import App from "./App";
import "./assets/styles/index.css";
import "./assets/styles/theme.scss";
import "./localization/i18n";
import "leaflet.animatedmarker/src/AnimatedMarker";
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/leaflet.markercluster";
import 'bootstrap-icons/font/bootstrap-icons.css';
import React from "react";
import ReactDOM from "react-dom";

ReactDOM.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
  document.getElementById("root")
);
