import api from "../api";
import { useGlobalApiState } from "../hooks/globalApiState";
import useRoleAccess from "../hooks/useRoleAccess";
import AddCircleOutlineIcon from "@mui/icons-material/AddCircleOutline";
import {
  Box,
  Chip,
  CircularProgress,
  FormHelperText,
  FormLabel,
  Stack,
  Typography,
} from "@mui/material";
import React from "react";

export default function RoleEditor({ roles, setRoles }) {
  const { canWriteResource } = useRoleAccess();
  const allRoles = useGlobalApiState(api.getRoles, null, { pick: (r) => r.data.items });

  if (!canWriteResource("role")) {
    return null;
  }

  function deleteRole(id) {
    const newRoles = roles.filter((c) => c.id !== id);
    setRoles(newRoles);
  }

  function handleAdd(newRole) {
    const newRoles = [...roles, newRole];
    setRoles(newRoles);
  }

  const hasRoleIds = new Set();
  roles.forEach((r) => hasRoleIds.add(r.id));

  return (
    <Box>
      <FormLabel>Roles</FormLabel>
      <FormHelperText>
        If you remove special roles like "admin", you will be logged out of this account.
      </FormHelperText>
      <Stack direction="row" gap={1} sx={{ marginTop: 1, flexWrap: "wrap" }}>
        {allRoles === null && <CircularProgress />}
        {allRoles?.map((r) => {
          const hasRole = hasRoleIds.has(r.id);
          const handler = hasRole ? () => deleteRole(r.id) : () => handleAdd(r);
          return (
            <Chip
              key={r.id}
              label={r.label}
              color={hasRole ? "success" : undefined}
              title={hasRole ? "Delete Role" : "Add Role"}
              deleteIcon={hasRole ? null : <AddCircleOutlineIcon />}
              onClick={handler}
              onDelete={handler}
            />
          );
        })}
        {allRoles && allRoles.length === 0 && (
          <Typography>
            * No roles available, ask developers for help if you see this
          </Typography>
        )}
      </Stack>
    </Box>
  );
}
