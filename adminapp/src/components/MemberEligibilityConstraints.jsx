import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import { useGlobalApiState } from "../hooks/globalApiState";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import useRoleAccess from "../hooks/useRoleAccess";
import useToggle from "../shared/react/useToggle";
import CancelIcon from "@mui/icons-material/Cancel";
import EditIcon from "@mui/icons-material/Edit";
import SaveIcon from "@mui/icons-material/Save";
import {
  Typography,
  MenuItem,
  Select,
  Chip,
  CircularProgress,
  Stack,
  FormControl,
  InputLabel,
} from "@mui/material";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import IconButton from "@mui/material/IconButton";
import { useTheme } from "@mui/styles";
import isEmpty from "lodash/isEmpty";
import map from "lodash/map";
import merge from "lodash/merge";
import startCase from "lodash/startCase";
import without from "lodash/without";
import React from "react";

export default function MemberEligibilityConstraints({
  memberConstraints,
  memberId,
  replaceMemberData,
}) {
  const editing = useToggle(false);
  // As constraints are added, their IDs go here.
  const [addedConstraintIds, setAddedConstraintIds] = React.useState([]);
  // When an existed constraint, or one in addedConstraintIds, has a status set, it is set here.
  const [updatedConstraints, setUpdatedConstraints] = React.useState({});
  // Stores the 'Add Constraint' dropdown.
  const [newConstraintId, setNewConstraintId] = React.useState(0);
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const eligibilityConstraints = useGlobalApiState(
    api.getEligibilityConstraintsMeta,
    null
  );
  const constraintNamesForIds = React.useMemo(
    () =>
      eligibilityConstraints
        ? Object.fromEntries(eligibilityConstraints.items.map((c) => [c.id, c.name]))
        : {},
    [eligibilityConstraints]
  );
  const memberConstraintIds = React.useMemo(
    () => memberConstraints.map((c) => c.constraint.id),
    [memberConstraints]
  );
  const combinedConstraintStatus = React.useMemo(
    () => ({
      ...Object.fromEntries(
        memberConstraints.map(({ status, constraint }) => [constraint.id, status])
      ),
      ...updatedConstraints,
    }),
    [memberConstraints, updatedConstraints]
  );
  const unusedConstraints = React.useMemo(() => {
    const usedConstraintIds = memberConstraintIds.concat(addedConstraintIds);
    return eligibilityConstraints
      ? eligibilityConstraints.items.filter((c) => !usedConstraintIds.includes(c.id))
      : [];
  }, [eligibilityConstraints, addedConstraintIds, memberConstraintIds]);

  function toggleEditing() {
    editing.toggle();
    setAddedConstraintIds([]);
    setUpdatedConstraints({});
    setNewConstraintId(0);
  }

  if (editing.isOff) {
    return (
      <DisplayConstraints
        memberConstraints={memberConstraints}
        toggleEditing={toggleEditing}
      />
    );
  }

  if (eligibilityConstraints === null) {
    return <CircularProgress />;
  }

  function saveChanges() {
    const idsAndStatuses = {};
    memberConstraints.forEach(
      ({ status, constraint }) => (idsAndStatuses[constraint.id] = status)
    );
    merge(idsAndStatuses, updatedConstraints);
    const values = map(idsAndStatuses, (status, constraintId) => ({
      constraintId,
      status,
    }));
    api
      .changeMemberEligibility({
        id: memberId,
        values,
      })
      .then((r) => {
        replaceMemberData(r.data);
        toggleEditing();
      })
      .catch(enqueueErrorSnackbar);
  }

  function modifyConstraint(constraintId, status) {
    if (status === removeStatus) {
      setAddedConstraintIds(without(addedConstraintIds, constraintId));
      return;
    }
    setUpdatedConstraints({ ...updatedConstraints, [constraintId]: status });
  }

  function handleAddConstraint() {
    setAddedConstraintIds([...addedConstraintIds, newConstraintId]);
    setUpdatedConstraints({ ...updatedConstraints, [newConstraintId]: "pending" });
    setNewConstraintId(0);
  }

  const editingProperties = [];
  // Add a constrol for each existing, and added, constraint.
  [...memberConstraintIds, ...addedConstraintIds].forEach((id) =>
    editingProperties.push({
      label: constraintNamesForIds[id],
      children: (
        <ConstraintStatusSelect
          id={id}
          activeStatus={combinedConstraintStatus[id]}
          statuses={eligibilityConstraints.statuses}
          showRemove={addedConstraintIds.includes(id)}
          onChange={(e) => modifyConstraint(id, e.target.value)}
        />
      ),
    })
  );

  if (!isEmpty(unusedConstraints)) {
    editingProperties.push({
      label: "Add Constraint",
      children: (
        <FormControl variant="filled" sx={{ display: "flex", flexDirection: "row" }}>
          <InputLabel id="constraint-name-label">Constraint</InputLabel>
          <Select
            labelId="constraint-name-label"
            value={newConstraintId}
            size="small"
            onChange={(e) => setNewConstraintId(e.target.value)}
          >
            <MenuItem value={0}>(None)</MenuItem>
            {unusedConstraints.map((c) => (
              <MenuItem key={c.id} value={c.id}>
                {c.name}
              </MenuItem>
            ))}
          </Select>
          <Button
            variant="contained"
            onClick={handleAddConstraint}
            disabled={newConstraintId === 0}
            sx={{ ml: 1 }}
          >
            Add
          </Button>
        </FormControl>
      ),
    });
  }
  return (
    <DetailGrid
      title={
        <>
          Eligibility Constraints
          <IconButton onClick={saveChanges}>
            <SaveIcon color="success" />
          </IconButton>
          <IconButton onClick={toggleEditing}>
            <CancelIcon color="error" />
          </IconButton>
        </>
      }
      properties={editingProperties}
    />
  );
}

function DisplayConstraints({ memberConstraints, toggleEditing }) {
  const { canWriteResource } = useRoleAccess();
  const displayables = [];
  if (isEmpty(memberConstraints)) {
    displayables.push({
      label:
        "* Member has no constraints. They can access any goods and services that are unconstrained.",
      variant: "outlined",
      color: "success",
    });
  } else {
    memberConstraints.forEach(({ status, constraint }) =>
      displayables.push({
        label: constraint.name,
        component: AdminLink,
        model: constraint,
        color: CONSTRAINT_STATUS_COLORS[status],
        variant: "outlined",
        sx: {
          "& .MuiChip-label": {
            fontWeight: "bold",
          },
        },
      })
    );
  }
  return (
    <Box mt={2}>
      <Typography variant="h6" gutterBottom mb={2}>
        Eligibility Constraints
        {canWriteResource("member") && (
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

const CONSTRAINT_STATUS_COLORS = {
  verified: "success",
  pending: "warning",
  rejected: "error",
};

function ConstraintStatusSelect({ id, activeStatus, statuses, showRemove, onChange }) {
  const theme = useTheme();
  const labelId = `constraint-status-label-${id}`;
  return (
    <FormControl variant="filled" sx={{ minWidth: 120 }}>
      <InputLabel id={labelId}>Constraint</InputLabel>
      <Select labelId={labelId} value={activeStatus} onChange={onChange}>
        {statuses.map((status) => (
          <MenuItem key={status} value={status}>
            <span
              style={{
                color: theme.palette[CONSTRAINT_STATUS_COLORS[status]].main,
              }}
            >
              {startCase(status)}
            </span>
          </MenuItem>
        ))}
        {showRemove && <MenuItem value={removeStatus}>Remove</MenuItem>}
      </Select>
    </FormControl>
  );
}

const removeStatus = "REMOVE";
