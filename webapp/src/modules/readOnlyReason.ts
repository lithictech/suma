import { t } from "../localization";
import isArray from "lodash/isArray";
import type { ReactElement } from "react";

/**
 * Return the translated read-only reason on the user.
 * If unlocalized, return just the key;
 * this is faster so is useful in boolean checks.
 *
 * Use this in cases where you want to check for specific reasons.
 *
 * This method is mostly useful because the fallback reason of technical
 * errors will get translated.
 * @param oneOf Read-only reason to look for.
 */
export default function readOnlyReason(
  user: CurrentMember,
  oneOf: string | string[],
  unlocalized?: boolean
): string | ReactElement {
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
  return t(`errors.${user.readOnlyReason}`);
}
