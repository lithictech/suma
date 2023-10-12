import relativeUrl from "../relativeUrl";
import setUrlPart from "../setUrlPart";
import React from "react";
import { useLocation, useNavigate } from "react-router-dom";

/**
 * Like useToggle, but on/off is controlled by the current URL has value
 * being equal to hashValue. Usually this is used to turn internal page state
 * like modals showing on or off.
 *
 * @param {string} hashValue If the hash of the location is this value, the toggle is on.
 * @return {Toggle}
 */
export default function useHashToggle(hashValue) {
  const location = useLocation();
  const navigate = useNavigate();
  const doNav = React.useCallback(
    (hash) => {
      navigate(setRelativeUrlPart({ location, hash }), { replace: true });
    },
    [location, navigate]
  );
  if (hashValue[0] !== "#") {
    hashValue = "#" + hashValue;
  }
  const isOn = location.hash === hashValue;
  return {
    isOn,
    isOff: !isOn,
    setState: (x) => doNav(x ? hashValue : ""),
    turnOn: () => doNav(hashValue),
    turnOff: () => doNav(""),
    toggle: () => doNav(isOn ? "" : hashValue),
  };
}

function setRelativeUrlPart(arg) {
  return relativeUrl({ location: setUrlPart(arg) });
}
