import "./Table.css";
import clsx from "clsx";
import React, { CSSProperties } from "react";

export interface TableTheme {
  headerColor?: string;
  backgroundColor1?: string;
  backgroundColor2?: string;
  hoverColor?: string;
}

export interface TableProps {
  children?: React.ReactNode;
  caption?: React.ReactNode;
  striped?: boolean;
  compact?: boolean;
  borders?: boolean;
  size?: "sm" | "md" | "lg";
  hover?: boolean;
  className?: string;
  style?: CSSProperties;
  theme?: TableTheme;
}

export default function Table({
  striped,
  hover,
  compact,
  borders = true,
  caption,
  size = "md",
  theme = {},
  className,
  style,
  children,
}: TableProps) {
  const cls = clsx(
    "table",
    striped && "table-striped",
    compact && "table-compact",
    hover && "table-hover",
    borders && "table-borders",
    `table-${size}`,
    className
  );
  const sty: Record<string, any> = { ...style };
  (Object.keys(theme) as Array<keyof TableTheme>).forEach((k) => {
    sty[themeKeys[k]] = theme[k];
  });
  if (theme.backgroundColor1) {
    sty["--tcolor-bg1"] = theme.backgroundColor1;
  }
  return (
    <table className={cls} style={sty}>
      {caption && <caption>{caption}</caption>}
      {children}
    </table>
  );
}

const themeKeys: Record<keyof TableTheme, string> = {
  headerColor: "--tcolor-header",
  backgroundColor1: "--tcolor-bg1",
  backgroundColor2: "--tcolor-bg2",
  hoverColor: "--tcolor-hover",
};
