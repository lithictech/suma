import React from "react";

/**
 * @param {boolean=} initial
 * @return {Toggle}
 */
export default function useToggle(initial) {
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

/**
 * @typedef Toggle
 * @property {function(): void} turnOff
 * @property {function(): void} turnOn
 * @property {function(): void} toggle
 * @property {function(boolean): void} setState
 * @property {boolean} isOn
 * @property {boolean} isOff
 */
