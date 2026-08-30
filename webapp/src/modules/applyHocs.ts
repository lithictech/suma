import { HOC } from "../hocs/hocs.ts";
import reduceRight from "lodash/reduceRight";
import React from "react";

export default function applyHocs(
  ...funcs: Array<HOC | React.ComponentType<any>>
): React.ComponentType<any> {
  const seed = funcs.pop();
  if (!seed) {
    throw new Error("applyHocs requires at least one function");
  }
  return reduceRight(
    funcs as HOC[],
    (memo, f) => f(memo),
    seed as React.ComponentType<any>
  );
}
