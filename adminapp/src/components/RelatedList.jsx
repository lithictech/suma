import useRoleAccess from "../hooks/useRoleAccess";
import useToggle from "../shared/react/useToggle";
import Link from "./Link";
import "./RelatedList.css";
import SimpleTable from "./SimpleTable";
import ListAltIcon from "@mui/icons-material/ListAlt";
import { Card, CardContent, Chip } from "@mui/material";
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
  emptyState,
  className,
  onAddNewClick,
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

  if (showMore === undefined) {
    showMore = true;
  }
  if (showMore === true) {
    showMore = DEFAULT_SHOW_MORE;
  }
  const { canWriteResource } = useRoleAccess();
  const addNew = Boolean(addNewLink || onAddNewClick) && canWriteResource(addNewRole);
  if (isEmpty(rows) && !addNew && !emptyState) {
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
    <Card>
      <CardContent>
        <div ref={topRef} />
        {title && (
          <Typography variant="h6" gutterBottom>
            {title} <ListCount items={rows} showMore={showMore} />
          </Typography>
        )}
        {addNew && (
          <Link to={addNewLink} onClick={onAddNewClick}>
            <ListAltIcon sx={{ verticalAlign: "middle", marginRight: "5px" }} />
            {addNewLabel}
          </Link>
        )}
        {isEmpty(rows) ? (
          emptyState
        ) : (
          <SimpleTable
            tableProps={tableProps}
            rows={rows}
            className={className}
            {...rest}
          />
        )}
        {showExpandCollapse && (
          <div className="related-list-expandcollapse">
            {rowsTrimmed && <div className="related-list-overlay"></div>}
            <Button variant="link" onClick={handleExpandCollapse}>
              {rowsTrimmed ? "Expand" : "Collapse"}
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function ListCount({ items, showMore }) {
  if (isEmpty(items)) {
    return null;
  }
  if (items.length <= showMore) {
    return null;
  }
  return (
    <Chip
      label={items.length}
      variant="outlined"
      size="small"
      color="secondary"
      sx={{ marginLeft: 0.5 }}
    />
  );
}
