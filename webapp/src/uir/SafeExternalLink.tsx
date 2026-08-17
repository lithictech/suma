import React from "react";

interface SafeExternalLinkProps {
  href: string;
  className?: string;
  children?: React.ReactNode;
  opener?: boolean;
  referrer?: boolean;
  component?: React.ElementType;
  [key: string]: any;
}

export default function SafeExternalLink({
  href,
  className,
  children,
  opener,
  referrer,
  component: Component,
  ...rest
}: SafeExternalLinkProps) {
  Component = Component || "a";
  return (
    <Component
      href={href}
      target="_blank"
      rel={[opener ? null : "noopener", referrer ? null : "noreferrer"]
        .filter(Boolean)
        .join(" ")}
      className={className}
      {...rest}
    >
      {children}
    </Component>
  );
}
