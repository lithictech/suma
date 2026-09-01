import clsx from "clsx";
import React from "react";

export interface TableProps {
  children?: React.ReactNode;
  striped?: boolean;
  hover?: boolean;
  className?: string;
}
export default function Table({ children }: TableProps) {
  return <table>{children}</table>;
}
