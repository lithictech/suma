import React from "react";

/**
 * Like useState, except that after <interval>, the state reverts back to <initialValue>.
 * @param interval {number}
 * @param initialValue {*}
 * @returns {[unknown,((function(*): void)|*)]}
 */
export default function useResettableTimerState(interval, initialValue) {
  const [state, setStateInner] = React.useState(initialValue);
  const timerHandler = React.useRef(0);
  const setState = React.useCallback(
    (v) => {
      if (timerHandler.current) {
        window.clearTimeout(timerHandler.current);
      }
      timerHandler.current = window.setTimeout(
        () => setStateInner(initialValue),
        interval
      );
      setStateInner(v);
    },
    [initialValue, interval]
  );
  return [state, setState];
}
