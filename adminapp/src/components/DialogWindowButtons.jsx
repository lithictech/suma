import CloseIcon from "@mui/icons-material/Close";
import FullscreenIcon from "@mui/icons-material/Fullscreen";
import FullscreenExitIcon from "@mui/icons-material/FullscreenExit";
import { Box } from "@mui/material";
import IconButton from "@mui/material/IconButton";
import React from "react";

/**
 * Show buttons on the top right of a dialog.
 */
export default function DialogWindowButtons({ fullscreenToggle, onExit }) {
  return (
    <Box
      sx={{
        position: "absolute",
        top: (t) => t.spacing(1),
        right: (t) => t.spacing(2),
        display: "flex",
        gap: 1,
      }}
    >
      {fullscreenToggle && (
        <IconButton
          sx={{
            color: (theme) => theme.palette.grey[500],
          }}
          onClick={fullscreenToggle.toggle}
        >
          {fullscreenToggle.isOn ? <FullscreenExitIcon /> : <FullscreenIcon />}
        </IconButton>
      )}
      {onExit && (
        <IconButton
          sx={{
            color: (theme) => theme.palette.grey[500],
          }}
          onClick={onExit}
        >
          <CloseIcon />
        </IconButton>
      )}
    </Box>
  );
}
