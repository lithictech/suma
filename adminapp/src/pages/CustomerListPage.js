import api from "../api";
import useGlobalStyles from "../hooks/useGlobalStyles";
import useListQueryControls from "../hooks/useListQueryControls";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Container,
  CircularProgress,
  Typography,
  TablePagination,
  TextField,
  Stack,
} from "@mui/material";
import clsx from "clsx";
import React from "react";
import { formatPhoneNumber } from "react-phone-number-input";

export default function CustomerListPage() {
  const classes = useGlobalStyles();
  const { page, setPage, perPage, setPerPage, search, setSearch } =
    useListQueryControls();
  const getCustomers = React.useCallback(() => {
    return api.getCustomers({ page: page + 1, perPage, search });
  }, [page, perPage, search]);
  const { state: listResponse, loading: listLoading } = useAsyncFetch(getCustomers, {
    default: {},
    pickData: true,
  });

  function handleSearchKeyPress(e) {
    if (e.key === "Enter") {
      e.preventDefault();
      console.log(e.key, e.code, e.target.value);
      setSearch(e.target.value);
      setPage(0);
    }
  }

  return (
    <Container className={classes.root} maxWidth="lg">
      <Stack direction="row" justifyContent="space-between" alignItems="center">
        <Typography variant="h5" gutterBottom>
          Customers
        </Typography>
        <TextField
          label="Search"
          variant="outlined"
          type="search"
          size="small"
          defaultValue={search}
          onKeyPress={handleSearchKeyPress}
        />
      </Stack>
      <TableContainer component={Paper}>
        <Table sx={{ minWidth: 650 }} aria-label="caption table" size="small">
          <TableHead>
            <TableRow>
              <TableCell align="center">ID</TableCell>
              <TableCell align="center">Phone Number</TableCell>
              <TableCell align="left">Name</TableCell>
              <TableCell align="left">Email</TableCell>
              <TableCell align="left">Registered</TableCell>
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
                  <TableCell component="th" scope="row" align="center">
                    {c.id}
                  </TableCell>
                  <TableCell align="center">{formatPhoneNumber("+" + c.phone)}</TableCell>
                  <TableCell align="left" className={clsx(c.name ? "" : "")}>
                    {c.name ? (
                      c.name
                    ) : (
                      <Typography variant="body2" color="textSecondary">
                        Unavailable
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell align="left">
                    {c.email ? (
                      c.email
                    ) : (
                      <Typography variant="body2" color="textSecondary">
                        Unavailable
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell align="left">{dayjs(c.createdAt).format("lll")}</TableCell>
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
          onPageChange={(_e, page) => setPage(page)}
          rowsPerPage={perPage}
          onRowsPerPageChange={(e) => setPerPage(e.target.value)}
          rowsPerPageOptions={[20, 50, 100]}
        />
      )}
    </Container>
  );
}
