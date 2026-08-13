import React from "react";

export default function ProgressBar({ value }) {
  const commonParams = {
    position: "absolute",
    height: "100%",
    borderRadius: "var(--border-radius-pill)",
  };
  return (
    <div style={{ height: 6, position: "relative" }}>
      <div
        style={{
          width: "100%",
          backgroundColor: "var(--color-secondary)",
          ...commonParams,
        }}
      ></div>
      <div
        style={{
          width: `${value}%`,
          backgroundColor: "var(--color-primary)",
          ...commonParams,
        }}
      />
    </div>
  );
}
