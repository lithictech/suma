import React from "react";

/**
 * @param initial
 * @return {{turnOff: (function(): void), turnOn: (function(): void), isOn: boolean, isOff: boolean, setState: (function(boolean): void)}}
 */
export default function useToggle(initial) {
  const [isOn, setState] = React.useState(initial || false);
  return {
    isOn,
    isOff: !isOn,
    setState,
    turnOn: () => setState(true),
    turnOff: () => setState(false),
    toggle: () => setState(!isOn),
  };
}
