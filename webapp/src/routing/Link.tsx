// import { resolvePath, RoutePath } from "./RoutePath.ts";
import { RoutePath } from "./RoutePath.ts";
import resolveRoutePath from "./resolveRoutePath.ts";
import React from "react";
import { Link as RLink, LinkProps as RLinkProps } from "react-router-dom";

interface LinkProps extends Omit<RLinkProps, "to"> {
  to: RoutePath;
}
const Link = React.forwardRef<HTMLAnchorElement, LinkProps>(function Link(
  { to, ...rest }: LinkProps,
  ref
) {
  return <RLink to={resolveRoutePath(to)} ref={ref} {...rest} />;
});
export default Link;
