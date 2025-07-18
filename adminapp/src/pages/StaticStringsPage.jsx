import api from "../api";
import Link from "../components/Link";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { CircularProgress, Stack, Typography } from "@mui/material";
import startCase from "lodash/startCase";
import React from "react";

export default function StaticStringsPage() {
  const { state, loading } = useAsyncFetch(api.getStaticStrings, {
    default: { items: [] },
    pickData: true,
  });
  if (loading) {
    return <CircularProgress />;
  }
  return (
    <>
      <Typography variant="h4" gutterBottom>
        Static Strings
      </Typography>
      <Stack gap={2}>
        {state.items.map(({ namespace }) => (
          <Typography key={namespace} variant="h5">
            <Link to={`/static-strings-namespace/${namespace}`}>
              {startCase(namespace)}
            </Link>
          </Typography>
        ))}
      </Stack>
    </>
  );
}
