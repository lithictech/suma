import { appError, AppError } from "./feedback.ts";
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
 *
 * @param user
 * @param oneOf Read-only reason to look for.
 */
export default function readOnlyReason(
  user: CurrentMember,
  oneOf: string | string[]
): AppError | null {
  const rs = user.readOnlyReason;
  if (!rs) {
    return null;
  }
  let useReason = false;
  if (rs === "read_only_technical_error") {
    useReason = true;
  } else if (rs === oneOf) {
    useReason = true;
  } else if (isArray(oneOf) && oneOf.includes(rs)) {
    useReason = true;
  }
  if (!useReason) {
    return null;
  }
  return appError(user.readOnlyReason);
}
