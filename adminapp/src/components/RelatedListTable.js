import SimpleTable from "./SimpleTable";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import _ from "lodash";
import React from "react";

export default function RelatedList({ title, tableProps, ...rest }) {
  tableProps = _.merge({ size: "small" }, tableProps);
  return (
    <Box mt={5}>
      <Typography variant="h6" gutterBottom>
        {title}
      </Typography>
      <SimpleTable tableProps={tableProps} {...rest} />
    </Box>
  );
}
