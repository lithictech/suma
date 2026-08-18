import "./Page.css";
import clsx from "clsx";
import React, { CSSProperties } from "react";

interface PageProps {
  buffer?: boolean;
  minHeight?: string | number;
  children: React.ReactNode;
  style?: CSSProperties;
  gap?: number;
}

export default function Page({ buffer, style, children, gap = 0 }: PageProps) {
  return (
    <div
      className={clsx("page", buffer ? "page-buffer" : "", `gap-${gap}`)}
      style={style}
    >
      {children}
    </div>
  );
}
