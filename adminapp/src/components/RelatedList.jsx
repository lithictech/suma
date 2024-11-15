import useRoleAccess from "../hooks/useRoleAccess";
import Link from "./Link";
import SimpleTable from "./SimpleTable";
import ListAltIcon from "@mui/icons-material/ListAlt";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import isEmpty from "lodash/isEmpty";
import merge from "lodash/merge";
import React from "react";

export default function RelatedList({
  title,
  tableProps,
  rows,
  addNewLabel,
  addNewLink,
  addNewRole,
  ...rest
}) {
  const { canWriteResource } = useRoleAccess();
  const addNew = Boolean(addNewLink) && canWriteResource(addNewRole);
  if (isEmpty(rows) && !addNew) {
    return null;
  }
  tableProps = merge({ size: "small" }, tableProps);
  return (
    <Box mt={5}>
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
      <SimpleTable tableProps={tableProps} rows={rows} {...rest} />
    </Box>
  );
}
