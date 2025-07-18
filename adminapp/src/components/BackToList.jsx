import Link from "./Link";
import LeftIcon from "@mui/icons-material/ChevronLeft";
import React from "react";

export default function BackToList({ to }) {
  return (
    <Link to={to} sx={{ verticalAlign: "bottom" }}>
      <LeftIcon />
    </Link>
  );
}
