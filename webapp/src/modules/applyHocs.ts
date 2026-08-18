import reduceRight from "lodash/reduceRight";

export default function applyHocs(...funcs: any[]) {
  const seed = funcs.pop();
  if (!seed) {
    throw new Error("applyHocs requires at least one function");
  }
  return reduceRight(
    funcs,
    (memo, f) => {
      return f(memo);
    },
    seed
  );
}
