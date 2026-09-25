import useToggle from "./useToggle";
import React from "react";

/**
 * Typically used for displaying a loader or spinner while the isPressed toggle
 * is turned on, then returns the callback after ms countdown wait time.
 * You can start/stop the countdown timer using isPressed toggle methods
 * (turnOn/turnOff), from any input source (mouse, touch, or keyboard events).
 * @param callback Returned after ms countdown is complete
 * @param ms Countdown wait time in milliseconds
 * @returns {Toggle}
 */

export default function useLongPress(callback, ms) {
  const isPressed = useToggle(false);

  React.useEffect(() => {
    if (isPressed.isOff) {
      return;
    }
    const timerId = setTimeout(callback, ms);

    return () => {
      clearTimeout(timerId);
    };
  }, [isPressed, callback, ms]);

  return isPressed;
}
