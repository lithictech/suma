import AppNav from "../components/AppNav.tsx";
import "./Page.css";
import clsx from "clsx";
import React, { CSSProperties } from "react";

interface PageProps {
  /**
   * Show a buffer around the content. Most pages should use this,
   * unless they go right to the edge.
   */
  buffer?: boolean;
  /** The gap of the stack. */
  gap?: number;
  /** If true, show the app nav. */
  appNav?: boolean;
  /** Main page content. */
  children: React.ReactNode;
  className?: string;
  style?: CSSProperties;
}

export default function Page({
  buffer = true,
  style,
  children,
  appNav,
  gap = 3,
  className,
}: PageProps) {
  const navRef = React.useRef<HTMLDivElement>(null);
  const [pageHeight, setPageHeight] = React.useState("100%");

  React.useLayoutEffect(() => {
    if (navRef.current) {
      setPageHeight(`calc(100% - ${navRef.current.clientHeight}px`);
    } else {
      setPageHeight("100%");
    }
  }, [appNav]);

  return (
    <div className="page-outer">
      <div
        className={clsx("page", buffer ? "page-buffer" : "", `gap-${gap}`, className)}
        style={{ height: pageHeight, ...style }}
      >
        {children}
      </div>
      {appNav && <AppNav ref={navRef} />}
    </div>
  );
}
