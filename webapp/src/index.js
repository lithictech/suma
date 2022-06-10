import App from "./App";
import "./assets/styles/index.css";
import "./assets/styles/theme.scss";
import "bootstrap-icons/font/bootstrap-icons.css";
import "leaflet.animatedmarker/src/AnimatedMarker";
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/leaflet.markercluster";
import React from "react";
import ReactDOM from "react-dom";
import { HelmetProvider } from "react-helmet-async";

ReactDOM.render(
  <React.StrictMode>
    <HelmetProvider>
      <App />
    </HelmetProvider>
  </React.StrictMode>,
  document.getElementById("root")
);
