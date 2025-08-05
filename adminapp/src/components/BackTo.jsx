import relativeLink from "../modules/relativeLink";
import Link from "./Link";
import LeftIcon from "@mui/icons-material/ChevronLeft";
import React from "react";

export default function BackTo({ to }) {
  const [relto] = relativeLink(to);
  return (
    <Link to={relto} sx={{ verticalAlign: "text-top" }}>
      <LeftIcon />
    </Link>
  );
}
