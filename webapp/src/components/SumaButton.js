import ExternalLink from "./ExternalLink";
import RLink from "./RLink";
import clsx from "clsx";
import merge from "lodash/merge";
import React from "react";
import Button from "react-bootstrap/Button";
import Stack from "react-bootstrap/Stack";

export default function SumaButton({ href, as, className, children, ...rest }) {
  const As = as || Button;
  rest = as === ExternalLink ? merge(rest, { component: Button }) : rest;
  return (
    <Stack direction="horizontal" className={clsx("justify-content-center", className)}>
      <As
        as={!as && RLink}
        size="sm"
        variant="outline-primary"
        style={{ minWidth: "33%" }}
        href={href}
        {...rest}
      >
        {children}
      </As>
    </Stack>
  );
}
