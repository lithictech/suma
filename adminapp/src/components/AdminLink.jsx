import relativeLink from "../modules/relativeLink";
import MatLink from "@mui/material/Link";
import get from "lodash/get";
import React from "react";
import { Link as RouterLink } from "react-router-dom";

const AdminLink = React.forwardRef(function AdminLink(
  { href, to, model, children, label, ...rest },
  ref
) {
  const [newTo, isRelative] = relativeLink(model?.adminLink || href || to || "");
  const newProps = {
    ...rest,
    ref,
    children: children || getLabel(model, label) || model?.id,
  };
  if (isRelative) {
    newProps.component = RouterLink;
    newProps.to = newTo;
  } else {
    newProps.href = newTo;
  }
  return <MatLink {...newProps} />;
});

export default AdminLink;

function getLabel(model, label) {
  if (!label || !model) {
    return null;
  }
  if (label === true) {
    return model.label;
  }
  return get(model, label).label;
}

AdminLink.Array = function (array, cb, sep = <></>) {
  return array.map((o, i) => (
    <React.Fragment key={JSON.stringify(o) + i}>
      {cb(o)}
      {i === array.length - 1 ? null : sep}
    </React.Fragment>
  ));
};
