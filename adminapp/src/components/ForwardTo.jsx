import relativeLink from "../modules/relativeLink";
import Link from "./Link";
import RightIcon from "@mui/icons-material/ChevronRight";
import React from "react";

export default function ForwardTo({ to }) {
  const [relto] = relativeLink(to);
  return (
    <Link to={relto} sx={{ verticalAlign: "text-top" }}>
      <RightIcon />
    </Link>
  );
}
