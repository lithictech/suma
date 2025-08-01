const colors = {
  high: "error",
  medium: "warning",
  low: "info",
};

export default function membershipVerificationDuplicateChanceColor(chance) {
  return colors[chance];
}
