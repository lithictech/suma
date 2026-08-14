/**
 * Call ref(v) or ref.current = v;.
 */
export default function setRef<T>(
  ref: ((value: T) => void) | { current: T } | null | undefined,
  value: T
) {
  if (!ref) {
    return;
  }
  if (typeof ref === "function") {
    ref(value);
    return;
  }
  ref.current = value;
}
