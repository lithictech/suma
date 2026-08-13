import { guttersClass, topMarginClass } from "../modules/constants";
import Container from "../ui/Container";
import clsx from "clsx";
import React from "react";

export default function LayoutContainer({ className, gutters, top, ...rest }) {
  const cls = clsx(top && topMarginClass, gutters && guttersClass, className);
  return <Container className={cls} {...rest} />;
}
