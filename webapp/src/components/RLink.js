import React from "react";
import { Link } from "react-router-dom";

/**
 * Use this where we need React Router links in Bootstrap,
 * like `<Button as={RLink} href="/x" />`.
 * This remaps the 'href' prop over to 'to'.
 * @returns {JSX.Element}
 * @constructor
 */
export default function RLink({ href, to, ...rest }) {
  return <Link to={to || href || "#"} {...rest} />;
}
