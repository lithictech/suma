import "./Tile.css";
import clsx from "clsx";
import React from "react";

interface TileProps {
  variant?: string;
  children?: React.ReactNode;
}

export default function Tile({ children, variant }: TileProps) {
  const cls = clsx("tile", `tile-${variant || "primary"}`);
  return <div className={cls}>{children}</div>;
}
