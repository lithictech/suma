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

export default function EligibilityConstraints({
  resource,
  constraints,
  modelId,
  replaceModelData,
  makeUpdateRequest,
}) {
  const { canWriteResource } = useRoleAccess();
  const editing = useToggle(false);
  // When we're editing, and something is toggled on and off, set the new state here.
  const [newConstraintStates, setNewConstraintStates] = React.useState({});
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const allConstraints = useGlobalApiState(api.getEligibilityConstraintsMeta, null, {
    pick: (r) => r.data.items,
  });

  function toggleEditing() {
    editing.toggle();
    setNewConstraintStates({});
  }

  const combinedConstraintStates = {};
  constraints.forEach((c) => (combinedConstraintStates[c.id] = true));
  merge(combinedConstraintStates, newConstraintStates);

  if (editing.isOff) {
    const displayables = [];
    if (_.isEmpty(constraints)) {
      // Show a chip if there are no constraints.
      displayables.push({
        label: "* Resource has no constraints. All members can access it.",
        variant: "outlined",
        color: "success",
      });
    } else {
      // Show a chip for ALL constraints, with the color indicating
      // whether the constraint is associated with the resource.
      // If all constraints aren't loaded yet,
      // show just the ones associated with the resource.
      const iterableConstraints = allConstraints || constraints;
      iterableConstraints?.forEach((c) =>
        displayables.push({
          label: c.name,
          component: AdminLink,
          model: c,
          color: combinedConstraintStates[c.id] ? "success" : "muted",
          variant: "outlined",
          sx: {
            "& .MuiChip-label": {
              fontWeight: combinedConstraintStates[c.id] ? "bold" : null,
            },
          },
        })
      );
    }
    return (
      <Box mt={2}>
        <Typography variant="h6" gutterBottom mb={2}>
          Eligibility Constraints
          {canWriteResource(resource) && (
            <IconButton onClick={toggleEditing}>
              <EditIcon color="info" />
            </IconButton>
          )}
        </Typography>
        <Stack direction="row" gap={1} sx={{ marginY: 1, flexWrap: "wrap" }}>
          {displayables.map(({ label, ...rest }) => (
            <Chip key={label} label={label} clickable {...rest} />
          ))}
        </Stack>
      </Box>
    );
  }

  function saveChanges() {
    const constraintIds = map(combinedConstraintStates, (state, cid) =>
      state ? cid : null
    ).filter(Boolean);
    makeUpdateRequest({ id: modelId, constraintIds })
      .then((r) => {
        replaceModelData(r.data);
        toggleEditing();
      })
      .catch(enqueueErrorSnackbar);
  }

  function handleClick(c) {
    setNewConstraintStates({
      ...newConstraintStates,
      [c.id]: !combinedConstraintStates[c.id],
    });
  }

  const loading = !allConstraints;
  return (
    <Box mt={2}>
      <Typography variant="h6" gutterBottom mb={2}>
        Eligibility Constraints{" "}
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
          {allConstraints.map((c) => (
            <Chip
              key={c.id}
              label={c.name}
              clickable
              color={combinedConstraintStates[c.id] ? "success" : "secondary"}
              variant="solid"
              onClick={() => handleClick(c)}
              onDelete={() => handleClick(c)}
              deleteIcon={
                combinedConstraintStates[c.id] ? (
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
