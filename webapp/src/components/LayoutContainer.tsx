import { guttersClass, topMarginClass } from "../modules/constants";
import clsx from "clsx";
import React from "react";
import Container from "react-bootstrap/Container";

interface LayoutContainerProps {
  className?: string;
  gutters?: boolean;
  top?: boolean;
  [rest: string]: any;
}

export default function LayoutContainer({
  className,
  gutters,
  top,
  ...rest
}: LayoutContainerProps) {
  const cls = clsx(top && topMarginClass, gutters && guttersClass, className);
  return <Container className={cls} {...rest} />;
}
