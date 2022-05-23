import MatLink from "@mui/material/Link";
import React from "react";
import { Link as RouterLink } from "react-router-dom";

const Link = React.forwardRef(function Link(props, ref) {
  if (props.href && !props.to) {
    props = { ...props, to: props.href };
  }
  return <MatLink component={RouterLink} {...props} ref={ref} />;
});

export default Link;
