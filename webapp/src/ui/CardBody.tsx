import "./CardBody.css";
import clsx from "clsx";
import React from "react";

interface CardBodyProps {
  className?: string;
  children?: React.ReactNode;
}

export default function CardBody({ className, children }: CardBodyProps) {
  const cls = clsx("card-body", className);
  return <div className={cls}>{children}</div>;
}
