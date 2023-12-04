import size from "lodash/size";

export default function createRelativeUrl(pathname, params) {
  if (size(params) === 0) {
    return pathname;
  }
  const up = new URLSearchParams(params);
  return `${pathname}?${up.toString()}`;
}
