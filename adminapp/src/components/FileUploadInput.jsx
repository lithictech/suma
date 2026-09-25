import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useToggle from "../shared/react/useToggle";
import UploadFileIcon from "@mui/icons-material/UploadFile";
import { Button, CircularProgress } from "@mui/material";
import ButtonGroup from "@mui/material/ButtonGroup";
import { useSnackbar } from "notistack";
import React from "react";

export default function FileUploadInput({ accept, label, onUpload }) {
  label = label || "Choose File";
  accept = accept || "*.*";
  const [file, setFile] = React.useState("");
  const uploading = useToggle();
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { enqueueSnackbar } = useSnackbar();
  const inputRef = React.useRef(null);

  function handleFileChange(e) {
    setFile(e.target.files?.[0] ?? null);
  }

  async function handleUpload(e) {
    e.preventDefault();
    if (!file) {
      return;
    }
    uploading.turnOn();

    try {
      await onUpload(file);
      enqueueSnackbar(`Uploaded ${file.name}`, { variant: "success" });
      setFile(null);
    } catch (err) {
      enqueueErrorSnackbar(err);
    } finally {
      uploading.turnOff();
    }
  }

  return (
    <ButtonGroup variant="outlined">
      <Button variant="outlined" onClick={() => inputRef.current?.click()}>
        {file ? file.name : label}
      </Button>
      {/* Hidden input lives beside the button so no interactive control is nested. */}
      <input
        ref={inputRef}
        type="file"
        accept={accept || "*.*"}
        hidden
        tabIndex={-1}
        onChange={handleFileChange}
      />

      <Button
        aria-label="Upload"
        variant="contained"
        disabled={!file || uploading.isOn}
        onClick={handleUpload}
      >
        {uploading.isOn ? <CircularProgress size={20} /> : <UploadFileIcon />}
      </Button>
    </ButtonGroup>
  );
}
