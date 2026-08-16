import "./Page.css";
import clsx from "clsx";
import React from "react";

interface PageProps {
  buffer: boolean;
  children: React.ReactNode;
}

export default function Page({ buffer, children }: PageProps) {
  return <div className={clsx("page", buffer ? "page-buffer" : "")}>{children}</div>;
}
