import DownloadIcon from "@mui/icons-material/Download";
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
import IconButton from "@mui/material/IconButton";
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
 * @param filters
 * @param title
 * @param tableProps
 * @param disableSearch
 * @param downloadUrl
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
  filters,
  columns,
  tableProps,
  disableSearch,
  downloadUrl,
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
        <Stack direction="row" justifyContent="flex-end" alignItems="center" gap={2}>
          {filters}
          {!disableSearch && (
            <TextField
              label="Search"
              variant="outlined"
              type="search"
              size="small"
              defaultValue={search}
              onKeyDown={handleSearchKeyDown}
            />
          )}
        </Stack>
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
                >
                  {col.sortable ? (
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
                  ) : (
                    col.label
                  )}
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
                <TableRow key={c.id || c.key}>
                  {columns.map((col, idx) => (
                    <TableCell
                      key={`${col.id}-${idx}`}
                      align={col.align}
                      {...(idx === 0 ? { component: "th", scope: "row" } : {})}
                      {...(col.props && col.props(c))}
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
        <div className={classes.pageControls}>
          {downloadUrl && (
            <IconButton href={downloadUrl}>
              <DownloadIcon />
            </IconButton>
          )}
          <TablePagination
            component="div"
            count={listResponse.totalCount || 0}
            page={page}
            onPageChange={(_e, page) => onParamsChange({ page })}
            rowsPerPage={perPage}
            onRowsPerPageChange={(e) => onParamsChange({ perPage: e.target.value })}
            rowsPerPageOptions={[20, 50, 100]}
          />
        </div>
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
  pageControls: {
    alignItems: "center",
    display: "flex",
    justifyContent: "flex-end",
  },
}));
