import _ from "lodash";

export default function applyHocs(...funcs) {
  return _.reduceRight(
    funcs,
    (memo, f) => {
      return f(memo);
    },
    funcs.pop()
  );
}
