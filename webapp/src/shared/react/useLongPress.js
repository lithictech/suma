import useToggle from "./useToggle";
import React from "react";

/**
 * Typically used for displaying a loader or spinner while the isPressed toggle
 * is turned on, then returns the callback after ms countdown wait time.
 * You can start/stop the countdown timer using isPressed toggle methods.
 * @param callback Returned after ms countdown is complete
 * @param ms Countdown wait time in milliseconds
 * @returns {Toggle}
 */

export default function useLongPress(callback, ms) {
  const isPressed = useToggle(false);

  React.useEffect(() => {
    let timerId = null;
    if (isPressed.isOff) {
      clearTimeout(timerId);
      return;
    }
    timerId = setTimeout(callback, ms);

    return () => {
      clearTimeout(timerId);
    };
  }, [isPressed, callback, ms]);

  return isPressed;
}
