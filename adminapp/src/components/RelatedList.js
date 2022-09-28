import SimpleTable from "./SimpleTable";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import _ from "lodash";
import React from "react";

export default function RelatedList({ title, tableProps, rows, ...rest }) {
  if (_.isEmpty(rows)) {
    return null;
  }
  tableProps = _.merge({ size: "small" }, tableProps);
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
