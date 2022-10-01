import AddIcon from "@mui/icons-material/Add";
import { Fab } from "@mui/material";
import { makeStyles } from "@mui/styles";
import clsx from "clsx";
import React from "react";

export default function FabAdd(props) {
  const classes = useStyles();
  return (
    <Fab
      color="primary"
      aria-label="add"
      className={clsx(classes.fab, props.className)}
      {...props}
    >
      <AddIcon />
    </Fab>
  );
}

const useStyles = makeStyles((theme) => ({
  fab: {
    position: "fixed !important",
    bottom: theme.spacing(4),
    right: theme.spacing(4),
  },
}));
