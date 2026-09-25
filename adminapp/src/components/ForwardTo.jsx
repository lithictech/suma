import relativeLink from "../modules/relativeLink";
import Link from "./Link";
import RightIcon from "@mui/icons-material/ChevronRight";
import React from "react";

/**
 * @param to Where to link to.
 * @param {string=} label Accessible name for the link. Defaults to 'Forward'.
 */
export default function ForwardTo({ to, label }) {
  const [relto] = relativeLink(to);
  return (
    <Link to={relto} aria-label={label || "Forward"} sx={{ verticalAlign: "text-top" }}>
      <RightIcon />
    </Link>
  );
}
