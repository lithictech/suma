import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { Button, Card, CardContent, CircularProgress, Stack } from "@mui/material";
import Typography from "@mui/material/Typography";
import React from "react";

export default function AdminActions({ adminActions, updateModel }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const [lastResponse, setLastResponse] = React.useState(null);
  const [actionLoadings, setActionLoadings] = React.useState({});

  function handleClick(e, url, params) {
    e.preventDefault();
    setActionLoadings({ ...actionLoadings, [url]: true });
    api
      .post(url, params)
      .then((r) => {
        if (r.headers["admin-action-handler"] === "update") {
          updateModel(r.data);
        } else {
          setLastResponse(r.data);
        }
      })
      .catch(enqueueErrorSnackbar)
      .finally(() => setActionLoadings({ ...actionLoadings, [url]: false }));
  }

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Actions
        </Typography>
        <Stack direction="row" gap={2}>
          {adminActions.map(({ label, url, params }) => (
            <Button
              key={url}
              variant="outlined"
              onClick={(e) => handleClick(e, url, params)}
            >
              {actionLoadings[url] && (
                <CircularProgress size="1rem" sx={{ marginRight: 1 }} />
              )}
              {label}
            </Button>
          ))}
        </Stack>
        {!!lastResponse && (
          <pre style={{ whiteSpace: "break-spaces", maxHeight: 400, overflow: "scroll" }}>
            {JSON.stringify(lastResponse, null, "  ")}
          </pre>
        )}
      </CardContent>
    </Card>
  );
}
