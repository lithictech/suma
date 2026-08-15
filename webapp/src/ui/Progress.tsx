import React from "react";

interface ProgressProps {
  value: number;
  size?: number;
  stroke?: number;
  variant?: "bar" | "circle";
  className?: ShimProps;
}

export default function Progress({
  value,
  size = 40,
  stroke = 6,
  variant = "bar",
}: ProgressProps) {
  if (variant === "circle") {
    return <ProgressCircle value={value} size={size} stroke={stroke} />;
  }
  return <ProgressBar value={value} stroke={stroke} />;
}

function ProgressBar({ value, stroke }: { value: number; stroke: number }) {
  const commonParams: React.CSSProperties = {
    position: "absolute",
    height: "100%",
    borderRadius: "var(--border-radius-pill)",
  };
  return (
    <div
      role="progressbar"
      aria-valuenow={value}
      aria-valuemin={0}
      aria-valuemax={100}
      style={{ height: stroke, position: "relative" }}
    >
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

function ProgressCircle({
  value,
  size,
  stroke,
}: {
  value: number;
  size: number;
  stroke: number;
}) {
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference * (1 - value / 100);
  return (
    <div
      role="progressbar"
      aria-valuenow={value}
      aria-valuemin={0}
      aria-valuemax={100}
      style={{ width: size, height: size, display: "inline-block" }}
    >
      <svg
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        style={{ transform: "rotate(-90deg)" }}
      >
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="var(--color-secondary)"
          strokeWidth={stroke}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="var(--color-primary)"
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          style={{ transition: "stroke-dashoffset var(--transition-base)" }}
        />
      </svg>
    </div>
  );
}
