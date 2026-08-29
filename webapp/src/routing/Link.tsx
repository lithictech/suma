import ExternalLink from "./ExternalLink.tsx";
import { ExternalUrl, RoutePathOrUrl } from "./RoutePath.ts";
import resolveRoutePath from "./resolveRoutePath.ts";
import React from "react";
import { Link as RLink, LinkProps as RLinkProps } from "react-router-dom";

export interface LinkProps extends Omit<RLinkProps, "to"> {
  to: RoutePathOrUrl;
}
const Link = React.forwardRef<HTMLAnchorElement, LinkProps>(function Link(
  { to, ...rest }: LinkProps,
  ref
) {
  if (to instanceof ExternalUrl) {
    return <ExternalLink href={to.url} {...rest} />;
  }
  return <RLink to={resolveRoutePath(to)} ref={ref} {...rest} />;
});
export default Link;
