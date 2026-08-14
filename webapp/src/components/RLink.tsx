import React from "react";
import { Link, LinkProps } from "react-router-dom";

interface RLinkProps extends Omit<LinkProps, "to"> {
  href?: string;
  to?: LinkProps["to"];
}

/**
 * Use this where we need React Router links in Bootstrap,
 * like `<Button as={RLink} href="/x" />`.
 * This remaps the 'href' prop over to 'to'.
 */
export default function RLink({ href, to, ...rest }: RLinkProps) {
  return <Link to={to || href || "#"} {...rest} />;
}
