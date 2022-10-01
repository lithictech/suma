import relativeLink from "../modules/relativeLink";
import MatLink from "@mui/material/Link";
import React from "react";
import { Link as RouterLink } from "react-router-dom";

const AdminLink = React.forwardRef(function AdminLink(
  { href, to, model, children, ...rest },
  ref
) {
  const [newTo, isRelative] = relativeLink(model?.adminLink || href || to || "");
  const newProps = { ...rest, ref, children: children || model?.id };
  if (isRelative) {
    newProps.component = RouterLink;
    newProps.to = newTo;
  } else {
    newProps.href = newTo;
  }
  return <MatLink {...newProps} />;
});

export default AdminLink;
