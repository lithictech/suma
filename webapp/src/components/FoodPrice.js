import Money from "../shared/react/Money";
import clsx from "clsx";
import React from "react";
import { Stack } from "react-bootstrap";

export default function FoodPrice({
  customerPrice,
  isDiscounted,
  undiscountedPrice,
  fs,
  bold,
  className,
}) {
  return (
    <Stack
      direction="horizontal"
      className={clsx("ms-auto", className, bold && `fw-semibold`, fs && `fs-${fs}`)}
    >
      {isDiscounted && (
        <strike className="me-2">
          <Money>{undiscountedPrice}</Money>
        </strike>
      )}
      <Money className={isDiscounted && "text-success"}>{customerPrice}</Money>
    </Stack>
  );
}
