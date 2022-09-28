import {
  CircularProgress,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TablePagination,
  TableRow,
  TableSortLabel,
  TextField,
  Typography,
} from "@mui/material";
import Box from "@mui/material/Box";
import { makeStyles } from "@mui/styles";
import { visuallyHidden } from "@mui/utils";
import React from "react";

/**
 *
 * @param page
 * @param perPage
 * @param search
 * @param order
 * @param orderBy
 * @param onParamsChange
 * @param listResponse
 * @param listLoading
 * @param title
 * @param tableProps
 * @param {Array<{label: string, id: string, align: any, sortable: boolean, render: function}>} columns
 */
export default function ResourceTable({
  page,
  perPage,
  search,
  order,
  orderBy,
  onParamsChange,
  listResponse,
  listLoading,
  title,
  columns,
  tableProps,
}) {
  const classes = useStyles();
  function handleSearchKeyDown(e) {
    if (e.key === "Enter") {
      e.preventDefault();
      onParamsChange({ search: e.target.value, page: 0 });
    }
  }

  return (
    <>
      <Stack direction="row" justifyContent="space-between" alignItems="center">
        <Typography variant="h5">{title}</Typography>
        <TextField
          label="Search"
          variant="outlined"
          type="search"
          size="small"
          defaultValue={search}
          onKeyDown={handleSearchKeyDown}
        />
      </Stack>
      <TableContainer component={Paper}>
        <Table {...tableProps}>
          <TableHead>
            <TableRow>
              {columns.map((col) => (
                <TableCell
                  key={col.id}
                  align={col.align}
                  sortDirection={orderBy === col.id ? order : false}
                  className={classes.cell}
                >
                  <TableSortLabel
                    active={orderBy === col.id}
                    direction={orderBy === col.id ? order || "desc" : "desc"}
                    onClick={() =>
                      onParamsChange({
                        order: cycleOrder(order),
                        orderBy: cycleOrder(order) ? col.id : undefined,
                      })
                    }
                  >
                    {col.label}
                    {orderBy === col.id ? (
                      <Box component="span" sx={visuallyHidden}>
                        {order === "desc" ? "sorted descending" : "sorted ascending"}
                      </Box>
                    ) : null}
                  </TableSortLabel>
                </TableCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {listLoading ? (
              <TableRow>
                <TableCell>
                  <CircularProgress />
                </TableCell>
              </TableRow>
            ) : (
              listResponse.items?.map((c) => (
                <TableRow key={c.id}>
                  {columns.map((col, idx) => (
                    <TableCell
                      key={`${col.id}-${idx}`}
                      align={col.align}
                      className={classes.cell}
                      {...(idx === 0 ? { component: "th", scope: "row" } : {})}
                    >
                      {col.render(c)}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
      {!listLoading && (
        <TablePagination
          component="div"
          count={listResponse.totalCount || 0}
          page={page}
          onPageChange={(_e, page) => onParamsChange({ page })}
          rowsPerPage={perPage}
          onRowsPerPageChange={(e) => onParamsChange({ perPage: e.target.value })}
          rowsPerPageOptions={[20, 50, 100]}
        />
      )}
    </>
  );
}
export function cycleOrder(value) {
  if (value === "desc") {
    return "asc";
  }
  if (value === "asc") {
    return undefined;
  }
  return "desc";
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
