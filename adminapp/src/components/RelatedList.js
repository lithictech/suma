import SimpleTable from "./SimpleTable";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import isEmpty from "lodash/isEmpty";
import merge from "lodash/merge";
import React from "react";

export default function RelatedList({ title, tableProps, rows, ...rest }) {
  if (isEmpty(rows)) {
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
      <SimpleTable tableProps={tableProps} rows={rows} {...rest} />
    </Box>
  );
}
