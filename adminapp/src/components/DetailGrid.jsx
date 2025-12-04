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
 * @param anchorLeft If true, use width:1% and white-space:no-wrap to make the left column
 *   use the minimum width.
 * @param footer Render this after the table.
 * @param {Array<DetailGridProperty>} properties
 * @param cardProps
 * @constructor
 */
export default function DetailGrid({ title, anchorLeft, footer, properties, cardProps }) {
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
  const leftStyle = { padding: 0.25, paddingRight: 1, border: "none" };
  if (anchorLeft) {
    leftStyle.width = "1%";
    leftStyle.whiteSpace = "nowrap";
  }
  return (
    <Card {...cardProps}>
      <CardContent sx={{ padding: 2 }}>
        {title && (
          <Typography variant="h6" gutterBottom mb={2}>
            {title}
          </Typography>
        )}
        <Table size="small">
          <TableBody>
            {usedProperties.map(({ label, value, tableCells, children }, index) => (
              <TableRow key={index}>
                {tableCells ? (
                  tableCells({ sx: { padding: 0.25, border: "none" } })
                ) : (
                  <>
                    <TableCell sx={leftStyle}>
                      <Label>{label}</Label>
                    </TableCell>
                    <TableCell sx={{ padding: 0.25, border: "none" }}>
                      <Value value={value}>{children}</Value>
                    </TableCell>
                  </>
                )}
              </TableRow>
            ))}
          </TableBody>
        </Table>
        {footer}
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
