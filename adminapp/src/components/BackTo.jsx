import relativeLink from "../modules/relativeLink";
import Link from "./Link";
import LeftIcon from "@mui/icons-material/ChevronLeft";
import React from "react";
import { useNavigate } from "react-router-dom";

export const BACK = "_BackTo_BACK";

export default function BackTo({ to }) {
  const navigate = useNavigate();
  const props = {};
  if (to === BACK) {
    props.to = "";
    props.onClick = () => navigate(-1);
  } else {
    const [relto] = relativeLink(to);
    props.to = relto;
  }
  return (
    <Link {...props} sx={{ verticalAlign: "text-top" }}>
      <LeftIcon />
    </Link>
  );
}

BackTo.BACK = BACK;
