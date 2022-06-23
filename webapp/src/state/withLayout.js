import "../assets/styles/screenloader.scss";
import TopNav from "../components/TopNav";
import React from "react";

export default function withLayout(options) {
  options = options || {};
  const nav = options.nav || "top";
  return (Wrapped) => {
    return (props) => {
      return (
        <div className="main-container">
          {nav === "top" && <TopNav />}
          <Wrapped {...props} />
        </div>
      );
    };
  };
}
