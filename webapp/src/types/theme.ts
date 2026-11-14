export type ThemeColor =
  | "primary"
  | "secondary"
  | "info"
  | "success"
  | "warning"
  | "danger";
export type ThemeSize = "sm" | "md" | "lg";
export type ThemeSpacing = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11;

type ThemeColorVariant = "strong" | "soft" | "text" | "mute" | "placeholder";

const fillVariants = ["soft", "strong"];

export class ThemeColorSpec {
  base: ThemeColor;
  variant: ThemeColorVariant;

  constructor(base: ThemeColor, variant: ThemeColorVariant = "strong") {
    this.base = base;
    this.variant = variant;
  }

  static parse(c: ThemeColor | ThemeColorSpec): ThemeColorSpec {
    if (typeof c === "string") {
      return new ThemeColorSpec(c);
    }
    return c;
  }

  toVar() {
    const parts = ["-"];
    if (fillVariants.includes(this.variant)) {
      parts.push("fill");
      parts.push(this.base);
      parts.push(this.variant);
    } else if (this.variant === "text") {
      parts.push("text");
      parts.push(this.base);
    } else {
      parts.push("text");
      parts.push(this.base);
      parts.push(this.variant);
    }
    const result = parts.join("-");
    return `var(${result})`;
  }
}
