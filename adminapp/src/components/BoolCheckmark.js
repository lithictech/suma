export default function BoolCheckmark({ children }) {
  if (children) {
    return "✅";
  }
  return "❌";
}
