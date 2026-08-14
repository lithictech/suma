import useToggle, { Toggle } from "./useToggle";
import React from "react";

/**
 * Typically used for displaying a loader or spinner while the isPressed toggle
 * is turned on, then returns the callback after ms countdown wait time.
 * You can start/stop the countdown timer using isPressed toggle methods.
 * @param callback Returned after ms countdown is complete
 * @param ms Countdown wait time in milliseconds
 */

export default function useLongPress(callback: () => void, ms: number): Toggle {
  const isPressed = useToggle(false);

  React.useEffect(() => {
    let timerId: ReturnType<typeof setTimeout> | null = null;
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
