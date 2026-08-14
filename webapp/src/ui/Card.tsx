import "./Card.css";
import clsx from "clsx";
import React from "react";

interface CardProps {
  className?: string;
  children?: React.ReactNode;
}

export default function Card({ className, children }: CardProps) {
  const cls = clsx(className, "card");
  return <div className={cls}>{children}</div>;
}
