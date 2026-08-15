import noop from "lodash/noop";
import React from "react";

export interface SwitchRowProps {
  title: string;
  text: string;
  checked: boolean;
}

export default function SwitchRow(props: SwitchRowProps) {
  noop(props);
  return <div />;
}
