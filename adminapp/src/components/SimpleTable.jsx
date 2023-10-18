import toValue from "../modules/toValue";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableContainer from "@mui/material/TableContainer";
import TableHead from "@mui/material/TableHead";
import TableRow from "@mui/material/TableRow";
import { makeStyles } from "@mui/styles";
import React from "react";

/**
 * Render a simple table.
 * @param rows Array of rows.
 * @param headers Header names.
 * @param toCells
 * @param keyCellIndex Index of a unique field that can be used as a 'key' in an array of cells.
 *   Defaults to 0 because that's normally the 'id' cell.
 * @param keyRowAttr Attribute of a 'row' object that can be used as a 'key'.
 *   Takes precendence over keyCellIndex.
 * @param getKey Function called with each row to generate a unique key.
 *   Takes precedence over keyRowAttr.
 * @param tableProps Props passed to the Table component.
 * @param {string|function} rowClass
 * @param className
 * @param center Center the table headers.
 * @constructor
 */
export default function SimpleTable({
  rows,
  headers,
  toCells,
  keyCellIndex,
  keyRowAttr,
  getKey,
  tableProps,
  rowClass,
  className,
  center,
}) {
  const classes = useStyles();

  function getKeyFunc(row, cells) {
    if (getKey) {
      return getKey(row);
    }
    if (keyRowAttr) {
      return row[keyRowAttr];
    }
    return cells[keyCellIndex || 0];
  }
  const tbl = (
    <TableContainer className={className}>
      <Table {...tableProps}>
        <TableHead>
          <TableRow>
            {headers.map((h) => (
              <TableCell
                key={h}
                className={classes.cell}
                align={center ? "center" : "inherit"}
              >
                {h}
              </TableCell>
            ))}
          </TableRow>
        </TableHead>
        <TableBody>
          {rows?.map((row) => {
            const cells = toCells(row);
            const key = getKeyFunc(row, cells);
            return (
              <TableRow key={key} className={toValue(rowClass, row)}>
                {cells.map((c, i) => (
                  <TableCell
                    key={i}
                    className={classes.cell}
                    align={center ? "center" : "inherit"}
                  >
                    {c}
                  </TableCell>
                ))}
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </TableContainer>
  );
  return tbl;
}

const useStyles = makeStyles(() => ({
  cell: {
    "&:last-child": {
      paddingRight: 0,
    },
    "&:first-child": {
      paddingLeft: 0,
    },
  },
}));
