import { dayjs } from "../modules/dayConfig";
import { Typography, Card, CardContent } from "@mui/material";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableRow from "@mui/material/TableRow";
import isBoolean from "lodash/isBoolean";
import isEmpty from "lodash/isEmpty";
import isUndefined from "lodash/isUndefined";
import React from "react";

/**
 * @param title The title of the detailgrid section
 * @param {Array<DetailGridProperty>} properties
 * @constructor
 */
export default function DetailGrid({ title, properties }) {
  const usedProperties = properties
    .filter(Boolean)
    .filter(({ hideEmpty, value, children }) => {
      if (!hideEmpty) {
        return true;
      }
      if (!isUndefined(value)) {
        return true;
      }
      return !isEmpty(children);
    });
  return (
    <Card>
      <CardContent sx={{ padding: 4 }}>
        {title && (
          <Typography variant="h6" gutterBottom mb={2}>
            {title}
          </Typography>
        )}
        <Table size="small">
          <TableBody>
            {usedProperties.map(({ label, value, children }, index) => (
              <TableRow key={index}>
                <TableCell sx={{ padding: 0.25, border: "none" }}>
                  <Label>{label}</Label>
                </TableCell>
                <TableCell sx={{ padding: 0.25, border: "none" }}>
                  <Value value={value}>{children}</Value>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
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
  let fmtVal = isUndefined(value) ? <>&nbsp;</> : value;
  if (value instanceof dayjs) {
    fmtVal = value.format("lll");
  } else if (isBoolean(value)) {
    fmtVal = value ? "✔️" : "❌";
  }
  return <Typography variant="body1">{fmtVal}</Typography>;
}

/**
 * @typedef DetailGridProperty
 * @property {string} label
 * @property {*} value If given, render this inside a typography.
 * @property {*} children If given, render this directly as the children. Should not be used with 'value'.
 */
