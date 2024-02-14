import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import Button from "@mui/material/Button";
import isNumber from "lodash/isNumber";
import { useSnackbar } from "notistack";
import React from "react";

export default function Copyable({ text, delay, inline, children }) {
  delay = isNumber(delay) ? delay : 2000;
  const { enqueueSnackbar } = useSnackbar();

  function onCopy(e) {
    e.preventDefault();
    navigator.clipboard.writeText(text || children);
    enqueueSnackbar("Copied to clipboard", {
      variant: "success",
      autoHideDuration: delay,
    });
  }
  const sx = inline && { px: "0!important", minWidth: "40px" };
  return (
    <React.Fragment>
      {children || text}
      <Button title="Copy" variant="link" sx={sx} onClick={onCopy}>
        <ContentCopyIcon />
      </Button>
    </React.Fragment>
  );
}
