import { dayjs } from "../modules/dayConfig";
import { Grid, Typography, Box } from "@mui/material";
import isEmpty from "lodash/isEmpty";
import React from "react";

/**
 * @param title The title of the detailgrid section
 * @param {Array<DetailGridProperty>} properties
 * @constructor
 */
export default function DetailGrid({ title, properties }) {
  const usedProperties = properties.filter(({ hideEmpty, value, children }) => {
    if (!hideEmpty) {
      return true;
    }
    const val = value || children;
    return !isEmpty(val);
  });
  return (
    <Box mt={2}>
      {title && (
        <Typography variant="h6" gutterBottom mb={2}>
          {title}
        </Typography>
      )}
      <Grid container spacing={2} alignItems="center" justifyContent="flex-end">
        {usedProperties.map(({ label, value, children }) => (
          <React.Fragment key={label}>
            <Grid item xs={4} sm={3} lg={2} sx={{ paddingTop: "5px!important" }}>
              <Label>{label}</Label>
            </Grid>
            <Grid item xs={8} sm={9} lg={10} sx={{ paddingTop: "5px!important" }}>
              <Value value={value}>{children}</Value>
            </Grid>
          </React.Fragment>
        ))}
      </Grid>
    </Box>
  );
}

function Label({ children }) {
  return (
    <Typography variant="body1" color="textSecondary" align="right">
      {children}:
    </Typography>
  );
}

function Value({ value, children }) {
  if (children) {
    return children;
  }
  let fmtVal = value || <>&nbsp;</>;
  if (value instanceof dayjs) {
    fmtVal = value.format("lll");
  }
  return <Typography variant="body1">{fmtVal}</Typography>;
}

/**
 * @typedef DetailGridProperty
 * @property {string} label
 * @property {*} value If given, render this inside a typography.
 * @property {*} children If given, render this directly as the children. Should not be used with 'value'.
 */
