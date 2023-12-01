import { guttersClass, topMarginClass } from "../modules/constants";
import clsx from "clsx";
import React from "react";
import Container from "react-bootstrap/Container";

export default function LayoutContainer({ className, gutters, top, ...rest }) {
  const cls = clsx(top && topMarginClass, gutters && guttersClass, className);
  return <Container className={cls} {...rest} />;
}
