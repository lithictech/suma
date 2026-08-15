import "./Tile.css";
import clsx from "clsx";
import React from "react";

interface TileProps {
  variant?: "primary" | "secondary" | "success" | "danger";
  children?: React.ReactNode;
}

export default function Tile({ children, variant = "primary" }: TileProps) {
  const cls = clsx("tile", `tile-${variant}`);
  return <div className={cls}>{children}</div>;
}
