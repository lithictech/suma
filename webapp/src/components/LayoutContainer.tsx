import { guttersClass, topMarginClass } from "../modules/constants";
import Container from "../ui/Container";
import clsx from "clsx";
import React from "react";

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
