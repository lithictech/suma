import App from "./App";
import Metrics from "./Metrics";
import "./assets/styles/imports";
import React from "react";
import { createRoot } from "react-dom/client";

createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
    <Metrics />
  </React.StrictMode>
);
