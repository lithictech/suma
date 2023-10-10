import { t } from "../localization";
import isArray from "lodash/isArray";

/**
 * Return the translated read-only reason on the user.
 * If unlocalized, return just the key;
 * this is faster so is useful in boolean checks.
 *
 * Use this in cases where you want to check for specific reasons.
 *
 * This method is mostly useful because the fallback reason of technical
 * errors will get translated.
 * @param user
 * @param oneOf {string, Array<string>} Read-only reason to look for.
 * @param unlocalized {boolean=}
 * @return {string}
 */
export default function readOnlyReason(user, oneOf, unlocalized) {
  const r = user.readOnlyReason;
  if (!r) {
    return "";
  }
  let useReason = false;
  if (r === "read_only_technical_error") {
    useReason = true;
  } else if (r === oneOf) {
    useReason = true;
  } else if (isArray(oneOf) && oneOf.includes(r)) {
    useReason = true;
  }
  if (!useReason) {
    return "";
  }
  if (unlocalized) {
    return r;
  }
  return t(`errors:${user.readOnlyReason}`);
}
