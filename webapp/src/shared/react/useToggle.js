import React from "react";

/**
 * @param initial
 * @return {Toggle}
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

/**
 * @typedef Toggle
 * @property {function(): void} turnOff
 * @property {function(): void} turnOn
 * @property {function(): void} toggle
 * @property {function(boolean): void} setState
 * @property {boolean} isOn
 * @property {boolean} isOff
 */
