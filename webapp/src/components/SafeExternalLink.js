import React from "react";

export default function SafeExternalLink({
  href,
  className,
  style,
  title,
  children,
  opener,
  referrer,
  component: Component,
  ...rest
}) {
  Component = Component || "a";
  return (
    <Component
      href={href}
      target="_blank"
      rel={[opener ? null : "noopener", referrer ? null : "noreferrer"]
        .filter(Boolean)
        .join(" ")}
      className={className}
      style={style}
      title={title}
      {...rest}
    >
      {children}
    </Component>
  );
}
