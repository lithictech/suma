import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import AdminLink from "./AdminLink";
import DetailGrid from "./DetailGrid";
import CancelIcon from "@mui/icons-material/Cancel";
import CheckIcon from "@mui/icons-material/Check";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import SaveIcon from "@mui/icons-material/Save";
import { MenuItem, Select } from "@mui/material";
import IconButton from "@mui/material/IconButton";
import _ from "lodash";
import React from "react";

export default function EligibilityConstraints({
  constraints,
  modelId,
  replaceModelData,
  makeUpdateRequest,
}) {
  const [editing, setEditing] = React.useState(false);
  const [updatedConstraints, setUpdatedConstraints] = React.useState([]);
  const [newConstraintId, setNewConstraintId] = React.useState(0);
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const { state: eligibilityConstraints, loading: eligibilityConstraintsLoading } =
    useAsyncFetch(api.getEligibilityConstraintsMeta, {
      pickData: true,
    });

  function startEditing() {
    setEditing(true);
    setUpdatedConstraints(constraints);
    setNewConstraintId(eligibilityConstraints[0]?.id);
  }

  if (!editing) {
    const properties = [];
    if (_.isEmpty(constraints)) {
      properties.push({
        label: "*",
        value: "Offering has no constraints. All members can access it.",
      });
    } else {
      constraints.forEach((constraint) =>
        properties.push({
          label: <AdminLink model={constraint}>{constraint.name}</AdminLink>,
          value: <CheckIcon />,
        })
      );
    }
    return (
      <div>
        <DetailGrid
          title={
            <>
              Eligibility Constraints
              <IconButton onClick={startEditing}>
                <EditIcon color="info" />
              </IconButton>
            </>
          }
          properties={properties}
        />
      </div>
    );
  }

  if (eligibilityConstraintsLoading) {
    return "Loading...";
  }

  function discardChanges() {
    setUpdatedConstraints([]);
    setEditing(false);
  }

  function saveChanges() {
    const constraintIds = updatedConstraints.map((c) => c.id);
    if (newConstraintId) {
      constraintIds.push(newConstraintId);
    }
    makeUpdateRequest({
      id: modelId,
      constraintIds,
    })
      .then((r) => {
        replaceModelData(r.data);
        setEditing(false);
      })
      .catch(enqueueErrorSnackbar);
  }

  function deleteConstraint(id) {
    setUpdatedConstraints(updatedConstraints.filter((c) => c.id !== id));
  }

  const properties = updatedConstraints.map((c) => ({
    label: c.name,
    children: (
      <IconButton onClick={() => deleteConstraint(c.id)}>
        <DeleteIcon color="error" />
      </IconButton>
    ),
  }));

  const existingConstraintIds = constraints.map((c) => c.id);
  const availableConstraints = eligibilityConstraints.items.filter(
    (c) => !existingConstraintIds.includes(c.id)
  );
  if (!_.isEmpty(availableConstraints)) {
    properties.push({
      label: "Add Constraint",
      children: (
        <div>
          <Select
            value={newConstraintId || ""}
            onChange={(e) => setNewConstraintId(Number(e.target.value))}
          >
            {availableConstraints.map((c) => (
              <MenuItem key={c.id} value={c.id}>
                {c.name}
              </MenuItem>
            ))}
          </Select>
        </div>
      ),
    });
  }
  return (
    <div>
      <DetailGrid
        title={
          <>
            Eligibility Constraints
            <IconButton onClick={saveChanges}>
              <SaveIcon color="success" />
            </IconButton>
            <IconButton onClick={discardChanges}>
              <CancelIcon color="error" />
            </IconButton>
          </>
        }
        properties={properties}
      />
    </div>
  );
}
