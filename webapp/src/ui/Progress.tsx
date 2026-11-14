import { ThemeColor, ThemeColorSpec } from "../types/theme";
import "./Progress.css";
import React from "react";

interface ProgressProps {
  value: number;
  size?: number;
  stroke?: number;
  variant?: "bar" | "circle";
  completeColor?: ThemeColor | ThemeColorSpec;
  incompleteColor?: ThemeColor | ThemeColorSpec;
}

export default function Progress({
  value,
  size = 56,
  stroke = 6,
  variant = "bar",
  completeColor = new ThemeColorSpec("primary", "strong"),
  incompleteColor = new ThemeColorSpec("secondary", "soft"),
}: ProgressProps) {
  const completeSpec = ThemeColorSpec.parse(completeColor);
  const incompleteSpec = ThemeColorSpec.parse(incompleteColor);
  if (variant === "circle") {
    return (
      <ProgressCircle
        value={value}
        size={size}
        stroke={stroke}
        completeColor={completeSpec}
        incompleteColor={incompleteSpec}
      />
    );
  }
  return (
    <ProgressBar
      value={value}
      stroke={stroke}
      completeColor={completeSpec}
      incompleteColor={incompleteSpec}
    />
  );
}

interface ProgressImplProps {
  value: number;
  stroke: number;
  completeColor: ThemeColorSpec;
  incompleteColor: ThemeColorSpec;
}

function ProgressBar({
  value,
  stroke,
  completeColor,
  incompleteColor,
}: ProgressImplProps) {
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
          backgroundColor: incompleteColor.toVar(),
          ...commonParams,
        }}
      ></div>
      <div
        style={{
          width: `${value}%`,
          backgroundColor: completeColor.toVar(),
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
  completeColor,
  incompleteColor,
}: { size: number } & ProgressImplProps) {
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference * (1 - value / 100);
  return (
    <div
      role="progressbar"
      aria-valuenow={value}
      aria-valuemin={0}
      aria-valuemax={100}
      className="progress-circle"
      style={{ width: size, height: size }}
    >
      <div className="progress-circle-text">{value}%</div>
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
          stroke={incompleteColor.toVar()}
          strokeWidth={stroke}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={completeColor.toVar()}
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
