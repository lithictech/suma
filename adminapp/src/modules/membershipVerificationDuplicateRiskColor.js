const colors = {
  high: "error",
  medium: "warning",
  low: "caution",
};

export default function membershipVerificationDuplicateRiskColor(risk) {
  return colors[risk.name];
}
