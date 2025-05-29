import isFunction from "lodash/isFunction";

export default function invokeIfFunc(f, ...args) {
  if (isFunction(f)) {
    return f(...args);
  }
  return f;
}
