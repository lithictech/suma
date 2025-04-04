import useRoleAccess from "../hooks/useRoleAccess";
import useToggle from "../shared/react/useToggle";
import Link from "./Link";
import "./RelatedList.css";
import SimpleTable from "./SimpleTable";
import ListAltIcon from "@mui/icons-material/ListAlt";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import Typography from "@mui/material/Typography";
import clsx from "clsx";
import isEmpty from "lodash/isEmpty";
import merge from "lodash/merge";
import React from "react";

const DEFAULT_SHOW_MORE = 7;

export default function RelatedList({
  title,
  tableProps,
  rows,
  showMore,
  addNewLabel,
  addNewLink,
  addNewRole,
  className,
  ...rest
}) {
  const expanded = useToggle();
  const topRef = React.useRef();

  const handleExpandCollapse = React.useCallback(
    (e) => {
      e.preventDefault();
      if (expanded.isOn) {
        expanded.turnOff();
        const targetPosition =
          topRef.current.getBoundingClientRect().top + window.scrollY;
        const approxNavHeight = 80;
        window.scrollTo({
          top: targetPosition - approxNavHeight,
          behavior: "smooth",
        });
      } else {
        expanded.turnOn();
      }
    },
    [expanded]
  );

  if (showMore === true) {
    showMore = DEFAULT_SHOW_MORE;
  }
  const { canWriteResource } = useRoleAccess();
  const addNew = Boolean(addNewLink) && canWriteResource(addNewRole);
  if (isEmpty(rows) && !addNew) {
    return null;
  }
  tableProps = merge({ size: "small" }, tableProps);
  const showExpandCollapse = showMore && rows.length > showMore;
  let rowsTrimmed = false;
  if (showMore && expanded.isOff && rows.length > showMore) {
    rowsTrimmed = true;
    className = clsx(className, "related-list-table-overflow");
  }
  return (
    <Box mt={5}>
      <div ref={topRef} />
      {title && (
        <Typography variant="h6" gutterBottom>
          {title}
        </Typography>
      )}
      {addNew && (
        <Link to={addNewLink}>
          <ListAltIcon sx={{ verticalAlign: "middle", marginRight: "5px" }} />
          {addNewLabel}
        </Link>
      )}
      <SimpleTable tableProps={tableProps} rows={rows} className={className} {...rest} />
      {showExpandCollapse && (
        <div className="related-list-expandcollapse">
          {rowsTrimmed && <div className="related-list-overlay"></div>}
          <Button variant="link" onClick={handleExpandCollapse}>
            {rowsTrimmed ? "Expand" : "Collapse"}
          </Button>
        </div>
      )}
    </Box>
  );
}
