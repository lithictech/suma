import "./IndeterminateLoader.css";
import IndeterminantLoaderSvg from "./IndeterminateLoaderSvg.jsx";
import clsx from "clsx";
import React from "react";

export default function IndeterminateLoader({ variant, size, className, style }) {
  if (variant === "plain") {
    return <SizedLoader size={size || 60} className={className} style={style} />;
  } else if (variant === "screen") {
    return <ScreenLoader size={size || 160} className={className} style={style} />;
  }
  return <ContentLoader size={size || 120} className={className} style={style} />;
}

function ScreenLoader({ size, className, style }) {
  const cls = clsx("indeterminate-loader-screen", className);
  return (
    <div className={cls} style={style}>
      <div className="indeterminate-loader-screen-centerer">
        <IndeterminantLoaderSvg size={size} />
      </div>
    </div>
  );
}

function ContentLoader({ size, className, style }) {
  const cls = clsx("indeterminate-loader-content", className);
  return (
    <div className={cls} style={style}>
      <IndeterminantLoaderSvg size={size} />
    </div>
  );
}

function SizedLoader({ size, className, style }) {
  return (
    <div className={className} style={style}>
      <IndeterminantLoaderSvg size={size} />
    </div>
  );
}
