import relativeUrl from "../relativeUrl";
import setUrlPart from "../setUrlPart";

/**
 * Like useToggle, but on/off is controlled by the current URL has value
 * being equal to hashValue. Usually this is used to turn internal page state
 * like modals showing on or off.
 *
 * @param {LocationLike} location
 * @param {function(string): void} navigate
 * @param {string} hashValue If the hash of the location is this value, the toggle is on.
 * @return {Toggle}
 */
export default function useHashToggle(location, navigate, hashValue) {
  if (hashValue[0] !== "#") {
    hashValue = "#" + hashValue;
  }
  const isOn = location.hash === hashValue;
  return {
    isOn,
    isOff: !isOn,
    setState: (x) => navigate(setRelativeUrlPart({ location, hash: x ? hashValue : "" })),
    turnOn: () => navigate(setRelativeUrlPart({ location, hash: hashValue })),
    turnOff: () => navigate(setRelativeUrlPart({ location, hash: "" })),
    toggle: () => navigate(setRelativeUrlPart({ location, hash: isOn ? "" : hashValue })),
  };
}

function setRelativeUrlPart(arg) {
  return relativeUrl({ location: setUrlPart(arg) });
}
