import App from "./App";
import Metrics from "./Metrics.jsx";
import "./assets/styles/imports.scss";
import "./assets/styles/rapiddev.css";
import "bootstrap-icons/font/bootstrap-icons.css";
import React from "react";
import { createRoot } from "react-dom/client";

createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
    <Metrics />
  </React.StrictMode>
);
