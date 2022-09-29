import MatLink from "@mui/material/Link";
import React from "react";
import { Link as RouterLink } from "react-router-dom";

const AdminLink = React.forwardRef(function AdminLink(
  { href, to, model, children, ...rest },
  ref
) {
  const propTo = model?.adminLink || href || to || "";
  const start = `${window.location.protocol}//${window.location.host}`;
  const newProps = { ...rest, ref, children: children || model?.id };
  if (propTo.startsWith(start)) {
    newProps.component = RouterLink;
    newProps.to = propTo.slice(start.length);
  } else {
    newProps.href = propTo;
  }
  return <MatLink {...newProps} />;
});

export default AdminLink;
