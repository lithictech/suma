import { dayjs } from "../modules/dayConfig";
import { Typography, Card, CardContent, Stack } from "@mui/material";
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
 * @param titleComponent Element to render the title as. Defaults to 'h2';
 *   the top-level grid on a detail page should use 'h1'.
 * @param beforeTitle Rendered before the title heading (like a 'back' link).
 * @param titleActions Rendered after the title heading, as a toolbar of controls
 *   (like edit/delete buttons). Kept outside the heading element.
 * @param anchorLeft If true, use width:1% and white-space:no-wrap to make the left column
 *   use the minimum width.
 * @param footer Render this after the table.
 * @param {Array<DetailGridProperty>} properties
 * @param cardProps
 * @constructor
 */
export default function DetailGrid({
  title,
  titleComponent,
  beforeTitle,
  titleActions,
  anchorLeft,
  footer,
  properties,
  cardProps,
}) {
  const titleId = React.useId();
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
  const hasTitle = Boolean(title);
  return (
    <Card {...cardProps}>
      <CardContent sx={{ padding: 2 }}>
        {(hasTitle || beforeTitle || titleActions) && (
          <Stack direction="row" alignItems="center" flexWrap="wrap" mb={2}>
            {beforeTitle}
            {hasTitle && (
              <Typography id={titleId} variant="h6" component={titleComponent || "h2"}>
                {title}
              </Typography>
            )}
            {titleActions}
          </Stack>
        )}
        <Table size="small" aria-labelledby={hasTitle ? titleId : undefined}>
          <TableBody>
            {usedProperties.map(({ label, value, tableCells, children }, index) => (
              <TableRow key={index}>
                {tableCells ? (
                  tableCells({ sx: { padding: 0.25, border: "none" } })
                ) : (
                  <>
                    <TableCell component="th" scope="row" sx={leftStyle}>
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
    fmtVal = value ? (
      <span role="img" aria-label="Yes">
        ✔️
      </span>
    ) : (
      <span role="img" aria-label="No">
        ❌
      </span>
    );
  }
  return <Typography variant="body1">{fmtVal}</Typography>;
}

/**
 * @typedef DetailGridProperty
 * @property {string} label
 * @property {*} value If given, render this inside a typography.
 * @property {*} children If given, render this directly as the children. Should not be used with 'value'.
 */
