import React from "react";

export default function BoolCheckmark({ children }) {
  if (children) {
    return (
      <span role="img" aria-label="Yes">
        ✅
      </span>
    );
  }
  return (
    <span role="img" aria-label="No">
      ❌
    </span>
  );
}
