import "./Tile.css";
import clsx from "clsx";
import React from "react";

export default function Tile({ children, variant }) {
  const cls = clsx("tile", `tile-${variant || "primary"}`);
  return <div className={cls}>{children}</div>;
}
