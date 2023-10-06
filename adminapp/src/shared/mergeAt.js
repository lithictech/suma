/**
 * Like _.pullAt, but does not mutate arr.
 * Returns the array with the indexed item removed.
 * @param {Array<T>} arr
 * @param {Number} idx
 * @param {object} fields
 * @return {Array<T>}
 */
export default function mergeAt(arr, idx, fields) {
  const r = [...arr]
  r[idx] = {...r[idx], ...fields}
  return r;
}