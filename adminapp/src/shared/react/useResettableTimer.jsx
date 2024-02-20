import useMountEffect from "./useMountEffect";
import useSessionStorageState from "./useSessionStorageState";
import React from "react";

/**
 * Like useState, except that after <interval>, the state reverts back to <initialValue>.
 * Note that this stores data in session storage, since we usually want this to persist
 * across renders.
 * @param storageKey {string} Unique key to store the timer in session storage.
 * @param interval {number}
 * @returns {[unknown,((function(*): void)|*)]}
 */
export default function useResettableTimer({ storageKey, interval }) {
  // Store the time we are supposed to clear the timer in session storage.
  let [clearAt, setClearAt] = useSessionStorageState(storageKey);
  clearAt = Number(clearAt);

  // Keep track of the timer handle, so we can clear it whenever we trigger the timer.
  const timerHandler = React.useRef(0);

  // Callers trigger() the timer, which enqueues it for the future.
  // Clear the existing timer, enqueue a timeout <interval> later,
  // and set the new clear time in storage.
  const trigger = React.useCallback(() => {
    window.clearTimeout(timerHandler.current);
    const newClearAt = Date.now() + interval;
    timerHandler.current = window.setTimeout(
      () => setClearAt(newClearAt.toString()),
      interval
    );
    setClearAt(newClearAt);
  }, [interval, setClearAt]);

  // When we mount, if we were able to load a 'clear at' from storage,
  // we want to enqueue a timeout to reset our time so it runs at that time.
  useMountEffect(() => {
    const now = Date.now();
    if (clearAt > now) {
      timerHandler.current = window.setTimeout(
        () => setClearAt(clearAt.toString()),
        clearAt - now
      );
    }
    return () => {
      // When we unmount, clear whatever times are running.
      // We'll load new timers on mount.
      window.clearTimeout(timerHandler.current);
    };
  }, []);

  // Return if the timer is active, and give the caller an ability to trigger the timer.
  return [clearAt > Date.now(), trigger];
}
