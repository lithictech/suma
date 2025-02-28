import api from "../api";
import { useGlobalApiState } from "../hooks/globalApiState";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useRoleAccess from "../hooks/useRoleAccess";
import useToggle from "../shared/react/useToggle";
import AdminLink from "./AdminLink";
import AddCircleOutlinedIcon from "@mui/icons-material/AddCircleOutlined";
import CancelIcon from "@mui/icons-material/Cancel";
import EditIcon from "@mui/icons-material/Edit";
import RemoveCircleOutlinedIcon from "@mui/icons-material/RemoveCircleOutlined";
import SaveIcon from "@mui/icons-material/Save";
import { Chip, Stack, Typography } from "@mui/material";
import Box from "@mui/material/Box";
import IconButton from "@mui/material/IconButton";
import _ from "lodash";
import map from "lodash/map";
import merge from "lodash/merge";
import React from "react";

export default function Programs({
  resource,
  programs,
  modelId,
  replaceModelData,
  makeUpdateRequest,
}) {
  const { canWriteResource } = useRoleAccess();
  const editing = useToggle(false);
  // When we're editing, and something is toggled on and off, set the new state here.
  const [newProgramStates, setNewProgramStates] = React.useState({});
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const allPrograms = useGlobalApiState(api.getProgramsMeta, null, {
    pick: (r) => r.data.items,
  });

  function toggleEditing() {
    editing.toggle();
    setNewProgramStates({});
  }

  const combinedProgramStates = {};
  programs.forEach((c) => (combinedProgramStates[c.id] = true));
  merge(combinedProgramStates, newProgramStates);

  if (editing.isOff) {
    const displayables = [];
    if (_.isEmpty(programs)) {
      // Show a chip if there are no programs.
      displayables.push({
        key: 0,
        label: "* Resource has no programs. All members and organizations can access it.",
        variant: "outlined",
        color: "success",
      });
    } else {
      // Show a chip for ALL programs, with the color indicating
      // whether the program is associated with the resource.
      // If all programs aren't loaded yet,
      // show just the ones associated with the resource.
      const iterablePrograms = allPrograms || programs;
      iterablePrograms?.forEach((c) =>
        displayables.push({
          key: c.id,
          label: c.name.en || c.name,
          component: AdminLink,
          model: c,
          color: combinedProgramStates[c.id] ? "success" : "muted",
          variant: "outlined",
          sx: {
            "& .MuiChip-label": {
              fontWeight: combinedProgramStates[c.id] ? "bold" : null,
            },
          },
        })
      );
    }
    return (
      <Box mt={2}>
        <Typography variant="h6" gutterBottom mb={2}>
          Programs
          {canWriteResource(resource) && (
            <IconButton onClick={toggleEditing}>
              <EditIcon color="info" />
            </IconButton>
          )}
        </Typography>
        <Stack direction="row" gap={1} sx={{ marginY: 1, flexWrap: "wrap" }}>
          {displayables.map(({ label, key, ...rest }) => (
            <Chip key={key} label={label} clickable {...rest} />
          ))}
        </Stack>
      </Box>
    );
  }

  function saveChanges() {
    const programIds = map(combinedProgramStates, (state, cid) =>
      state ? cid : null
    ).filter(Boolean);
    makeUpdateRequest({ id: modelId, programIds })
      .then((r) => {
        replaceModelData(r.data);
        toggleEditing();
      })
      .catch(enqueueErrorSnackbar);
  }

  function handleClick(c) {
    setNewProgramStates({
      ...newProgramStates,
      [c.id]: !combinedProgramStates[c.id],
    });
  }

  const loading = !allPrograms;
  return (
    <Box mt={2}>
      <Typography variant="h6" gutterBottom mb={2}>
        Programs{" "}
        {!loading && (
          <IconButton onClick={saveChanges}>
            <SaveIcon color="success" />
          </IconButton>
        )}
        <IconButton onClick={toggleEditing}>
          <CancelIcon color="error" />
        </IconButton>
      </Typography>
      {!loading && (
        <Stack direction="row" gap={1} sx={{ marginY: 1, flexWrap: "wrap" }}>
          {allPrograms.map((c) => (
            <Chip
              key={c.id}
              label={c.name.en || c.name}
              clickable
              color={combinedProgramStates[c.id] ? "success" : "secondary"}
              variant="solid"
              onClick={() => handleClick(c)}
              onDelete={() => handleClick(c)}
              deleteIcon={
                combinedProgramStates[c.id] ? (
                  <RemoveCircleOutlinedIcon />
                ) : (
                  <AddCircleOutlinedIcon />
                )
              }
            />
          ))}
        </Stack>
      )}
    </Box>
  );
}
