import React from "react";

export interface Toggle {
  turnOff: () => void;
  turnOn: () => void;
  toggle: () => void;
  setState: (isOn: boolean) => void;
  isOn: boolean;
  isOff: boolean;
}

export default function useToggle(initial?: boolean): Toggle {
  const [isOn, setState] = React.useState(initial || false);
  const toggle = React.useMemo(
    () => ({
      isOn,
      isOff: !isOn,
      setState,
      turnOn: () => setState(true),
      turnOff: () => setState(false),
      toggle: () => setState(!isOn),
    }),
    [isOn]
  );
  return toggle;
}
