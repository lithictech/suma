import "./Table.css";
import React, { CSSProperties } from "react";

export interface TableProps {
  children?: React.ReactNode;
  striped?: boolean;
  hover?: boolean;
  className?: string;
  style?: CSSProperties;
}
export default function Table({ className, style, children }: TableProps) {
  return (
    <table className={className} style={style}>
      {children}
    </table>
  );
}
