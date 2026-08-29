import "./Nav.css";
import clsx from "clsx";
import React from "react";

export interface NavProps {
  children?: React.ReactNode;
  className?: string;
}

const Nav = React.forwardRef<HTMLDivElement, NavProps>(function Nav(
  { className, children }: NavProps,
  ref
) {
  const cls = clsx("nav", className);
  return (
    <div ref={ref} className={cls}>
      {children}
    </div>
  );
});
export default Nav;
