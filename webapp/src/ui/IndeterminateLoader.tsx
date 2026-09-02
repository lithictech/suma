import "./IndeterminateLoader.css";
import IndeterminantLoaderSvg from "./IndeterminateLoaderSvg";
import clsx from "clsx";
import React from "react";

interface IndeterminateLoaderProps {
  variant?: "plain" | "screen" | "content";
  size?: number;
  className?: string;
  style?: React.CSSProperties;
}

export default function IndeterminateLoader({
  variant,
  size,
  className,
  style,
}: IndeterminateLoaderProps) {
  if (variant === "plain") {
    return <SizedLoader size={size || 60} className={className} style={style} />;
  } else if (variant === "screen") {
    return <ScreenLoader size={size || 160} className={className} style={style} />;
  }
  return <ContentLoader size={size || 120} className={className} style={style} />;
}

interface SizedProps {
  size: number;
  className?: string;
  style?: React.CSSProperties;
}

function ScreenLoader({ size, className, style }: SizedProps) {
  const cls = clsx("indeterminate-loader", "indeterminate-loader-screen", className);
  return (
    <div className={cls} style={style}>
      <div className="indeterminate-loader-screen-centerer">
        <IndeterminantLoaderSvg size={size} />
      </div>
    </div>
  );
}

function ContentLoader({ size, className, style }: SizedProps) {
  const cls = clsx("indeterminate-loader", "indeterminate-loader-content", className);
  return (
    <div className={cls} style={style}>
      <IndeterminantLoaderSvg size={size} />
    </div>
  );
}

function SizedLoader({ size, className, style }: SizedProps) {
  const cls = clsx("indeterminate-loader", className);
  return (
    <div className={cls} style={style}>
      <IndeterminantLoaderSvg size={size} />
    </div>
  );
}
