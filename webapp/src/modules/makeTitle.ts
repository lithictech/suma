import { t } from "../localization";

export default function makeTitle(...parts: string[]): string {
  const allParts = [...parts, t("titles.suma_app")];
  return allParts.join(" | ");
}
