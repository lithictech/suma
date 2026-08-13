import reduceRight from "lodash/reduceRight";

export default function applyHocs(...funcs: Array<(x: any) => any>) {
  return reduceRight(
    funcs,
    (memo, f) => {
      return f(memo);
    },
    funcs.pop()
  );
}
