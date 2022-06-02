import { dayjs } from "../modules/dayConfig";
import Unavailable from "./Unavailable";
import { Grid, Typography, Box } from "@mui/material";
import _ from "lodash";
import React from "react";

/**
 * @param {Array<DetailGridProperty>} properties
 * @constructor
 */
export default function DetailGrid({ title, properties }) {
  const usedProperties = properties.filter(({ hideEmpty, value, children }) => {
    if (!hideEmpty) {
      return true;
    }
    const val = value || children;
    return !_.isEmpty(val);
  });
  return (
    <Box>
      {title && (
        <Typography variant="h6" mt={2} mb={1}>
          {title}
        </Typography>
      )}
      <Grid container spacing={2}>
        <Grid item sx={{ width: "180px" }}>
          {usedProperties.map(({ label }) => (
            <Label key={label}>{label}</Label>
          ))}
        </Grid>
        <Grid item>
          {usedProperties.map(({ label, value, children }) => (
            <Value key={label} value={value}>
              {children}
            </Value>
          ))}
        </Grid>
      </Grid>
    </Box>
  );
}

function Label({ children }) {
  return (
    <Typography variant="body1" color="textSecondary" align="right" gutterBottom>
      {children}:
    </Typography>
  );
}

function Value({ value, children }) {
  if (value) {
    let fmtVal = value;
    if (value instanceof dayjs) {
      fmtVal = value.format("lll");
    }
    return (
      <Typography variant="body1" gutterBottom>
        {fmtVal}
      </Typography>
    );
  }
  if (children) {
    return children;
  }
  return <Unavailable variant="body1" gutterBottom />;
}

/**
 * @typedef DetailGridProperty
 * @property {string} label
 * @property {*} value If given, render this inside a typography.
 * @property {*} children If given, render this directly as the children. Should not be used with 'value'.
 */
