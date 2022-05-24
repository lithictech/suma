/**
 * Invoke value if value is a function,
 * return it as-is otherwise.
 * If value is a function, it is invoked as `value(...args)`.
 *
 * Used so we can accept a function that returns a class/style object,
 * or a function/object.
 */
export default function toValue(value, ...args) {
  if (typeof value === "function") {
    return value(...args);
  }
  return value;
}
