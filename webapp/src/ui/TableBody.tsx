import React from "react";

export interface TableBodyProps {
  children?: React.ReactNode;
}
export default function TableBody({ children }: TableBodyProps) {
  return <tbody>{children}</tbody>;
}
