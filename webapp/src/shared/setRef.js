import has from "lodash/has";

/**
 * Call ref(v) or ref.current = v;.
 */
export default function setRef(ref, value) {
  if (!ref) {
    return;
  }
  if (has(ref, "current")) {
    ref.current = value;
    return;
  }
  ref(value);
}
