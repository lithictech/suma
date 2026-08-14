import "./Nav.css";
import React from "react";

export default function Nav({ children }: { children?: React.ReactNode }) {
  return <div className="nav">{children}</div>;
}
