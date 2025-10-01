import useErrorSnackbar from "../hooks/useErrorSnackbar";
import LoadingButton from "@mui/lab/LoadingButton";
import {
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from "@mui/material";
import React from "react";

export default function SupportNoteModal({
  toggle,
  note,
  setNote,
  apiCreate,
  apiUpdate,
  apiParams,
  onSubmitted,
}) {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const [loading, setLoading] = React.useState(false);

  function handleSave() {
    const params = { ...apiParams, content: note.content };
    if (note.id) {
      params.noteId = note.id;
    }
    setLoading(true);
    const promise = (note.id ? apiUpdate : apiCreate)(params);
    promise
      .then(onSubmitted)
      .catch(enqueueErrorSnackbar)
      .finally(() => setLoading(false));
  }
  return (
    <Dialog onClose={toggle.turnOff} open={toggle.isOn} maxWidth="md" fullWidth>
      <DialogTitle>{note.id ? "Edit Note" : "Add Note"}</DialogTitle>
      <DialogContent>
        <TextField
          value={note.content || ""}
          label="Content"
          variant="outlined"
          fullWidth
          required
          sx={{ marginTop: 1 }}
          onChange={(e) => setNote({ ...note, content: e.target.value })}
        />
      </DialogContent>
      <DialogActions>
        <Button variant="outlined" color="secondary" onClick={toggle.turnOff}>
          Cancel
        </Button>
        <LoadingButton onClick={handleSave} loading={loading} variant="contained">
          Save
        </LoadingButton>
      </DialogActions>
    </Dialog>
  );
}
