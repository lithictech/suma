import "./Page.css";
import clsx from "clsx";
import React, { CSSProperties } from "react";

interface PageProps {
  buffer: boolean;
  minHeight?: string | number;
  children: React.ReactNode;
  style?: CSSProperties;
}

export default function Page({ buffer, style, children }: PageProps) {
  return (
    <div className={clsx("page", buffer ? "page-buffer" : "")} style={style}>
      {children}
    </div>
  );
}
