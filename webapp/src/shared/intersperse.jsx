/**
 * Return an array with the separator interspersed between
 * each element of the input array.
 *
 * > intersperse([1,2,3], 0)
 * [1,0,2,0,3]
 * > intersperse([1,2,3], (i) => <br key={i} />)
 * [1,<br key={1} />,2,<br key={3} />,3]
 */
export default function intersperse(arr, sep) {
  if (arr.length === 0) {
    return [];
  }

  const sepCb = typeof sep !== "function" ? () => sep : sep;
  return arr.slice(1).reduce(
    function (xs, x, i) {
      return xs.concat([sepCb(i), x]);
    },
    [arr[0]]
  );
}
