import "./assets/styles/index.css";
import "./assets/styles/theme.scss";
import "./localization/i18n";
import "bootstrap-icons/font/bootstrap-icons.css";
import "leaflet.animatedmarker/src/AnimatedMarker";
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/leaflet.markercluster";
import React from "react";
import ReactDOM from "react-dom";

// Lazyload app after localization loads
const App = React.lazy(() => import("./App.js"));

ReactDOM.render(
  <React.StrictMode>
    <React.Suspense fallback={null}>
      <App />
    </React.Suspense>
  </React.StrictMode>,
  document.getElementById("root")
);
