import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import {
  Button,
  Card,
  CardContent,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  Stack,
} from "@mui/material";
import Typography from "@mui/material/Typography";
import size from "lodash/size";
import React from "react";

export default function AdminActions({ adminActions, updateModel }) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const [lastResponse, setLastResponse] = React.useState(null);
  const [actionLoadings, setActionLoadings] = React.useState({});
  const [confirmingAction, setConfirmingAction] = React.useState(null);

  if (!size(adminActions)) {
    return null;
  }

  function submitAction(e, action) {
    setActionLoadings({ ...actionLoadings, [action.url]: true });
    api
      .post(action.url, action.params)
      .then((r) => {
        if (r.headers["admin-action-handler"] === "update") {
          updateModel(r.data);
        } else {
          setLastResponse(r.data);
        }
        setConfirmingAction(null); // In case this came from the confirmation modal
      })
      .catch(enqueueErrorSnackbar)
      .finally(() => setActionLoadings({ ...actionLoadings, [action.url]: false }));
  }

  /**
   * @param {MouseEvent} e
   * @param {AdminAction} action
   */
  function handleClick(e, action) {
    e.preventDefault();
    if (action.confirmationPrompt) {
      setConfirmingAction(action);
    } else {
      submitAction(e, action);
    }
  }

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Actions
        </Typography>
        <Stack direction="row" gap={2}>
          {adminActions.map(({ label, url, ...rest }) => (
            <Button
              key={url}
              variant="outlined"
              onClick={(e) => handleClick(e, { url, ...rest })}
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
      <Dialog open={Boolean(confirmingAction)} onClose={() => setConfirmingAction(null)}>
        <DialogContent>
          <DialogContentText>{confirmingAction?.confirmationPrompt}</DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmingAction(null)}>Cancel</Button>
          <Button
            variant="contained"
            color="error"
            onClick={(e) => submitAction(e, confirmingAction)}
          >
            Confirm
          </Button>
        </DialogActions>
      </Dialog>
    </Card>
  );
}
