/**
 * Like _.pullAt, but does not mutate arr.
 * Returns the array with the indexed item removed.
 * @param {Array<T>} arr
 * @param {Number} idx
 * @return {Array<T>}
 */
export default function withoutAt(arr, idx) {
  const r = [...arr];
  r.splice(idx, 1);
  return r;
}
