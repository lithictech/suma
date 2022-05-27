import api from "../api";
import useAsyncFetch from "../hooks/useAsyncFetch";
import useStyles from "../hooks/useStyles";
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
} from "@mui/material";
import clsx from "clsx";
import dayjs from "dayjs";
import _ from "lodash";
import React from "react";
import { formatPhoneNumber } from "react-phone-number-input";

export default function CustomersPage() {
  const classes = useStyles();
  const { state: customers, loading: listLoading } = useAsyncFetch(api.getCustomers, {
    default: {},
    pickData: true,
  });

  return (
    <Container className={classes.root} maxWidth="lg">
      <Typography variant="h5" gutterBottom>
        Customers
      </Typography>
      <TableContainer component={Paper}>
        <Table sx={{ minWidth: 650 }} aria-label="caption table">
          <caption>List of all customers in the database.</caption>
          <TableHead>
            <TableRow>
              <TableCell align="center">ID</TableCell>
              <TableCell align="center">Phone Number</TableCell>
              <TableCell align="left">Name</TableCell>
              <TableCell align="left">Email</TableCell>
              <TableCell align="left">Registered</TableCell>
            </TableRow>
          </TableHead>
          <TableBody stripedRows>
            {listLoading ? (
              <CircularProgress />
            ) : !_.isEmpty(customers.items) ? (
              customers.items.map((c) => (
                <TableRow key={c.name}>
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
            ) : (
              <TableRow>
                <TableCell>
                  <Typography>There are no customers found in the database.</Typography>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </Container>
  );
}
