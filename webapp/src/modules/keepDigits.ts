export default function (s: string): string {
  return (s || "").replace(/\D/g, "");
}
