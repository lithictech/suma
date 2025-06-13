import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { Button, Card, CardContent, CircularProgress } from "@mui/material";
import Typography from "@mui/material/Typography";
import React from "react";

export default function AdminActions({ adminActions }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const [actionResponses, setActionResponses] = React.useState({});
  const [actionLoadings, setActionLoadings] = React.useState({});

  function handleClick(e, url, params) {
    e.preventDefault();
    setActionLoadings({ ...actionLoadings, [url]: true });
    api
      .post(url, params)
      .then((r) => setActionResponses({ ...actionResponses, [url]: r.data }))
      .catch(enqueueErrorSnackbar)
      .finally(() => setActionLoadings({ ...actionLoadings, [url]: false }));
  }

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Actions
        </Typography>
        {adminActions.map(({ label, url, params }) => (
          <div key={url}>
            <Button variant="outlined" onClick={(e) => handleClick(e, url, params)}>
              {actionLoadings[url] && (
                <CircularProgress size="1rem" sx={{ marginRight: 1 }} />
              )}
              {label}
            </Button>
            {actionResponses[url] && (
              <pre style={{ whiteSpace: "break-spaces" }}>
                {JSON.stringify(actionResponses[url], null, "  ")}
              </pre>
            )}
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
