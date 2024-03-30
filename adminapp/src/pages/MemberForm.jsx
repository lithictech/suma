import AddressInputs from "../components/AddressInputs";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import theme from "../theme";
import AddCircleOutlineIcon from "@mui/icons-material/AddCircleOutline";
import {
  Box,
  Chip,
  FormHelperText,
  FormLabel,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import isEmpty from "lodash/isEmpty";
import merge from "lodash/merge";
import React from "react";

export default function MemberForm({
  resource,
  setField,
  setFieldFromInput,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={"Update Member"}
      subtitle="Edit member account information"
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <ResponsiveStack>
          <TextField
            {...register("name")}
            label="Name"
            name="name"
            value={resource.name || ""}
            type="text"
            variant="outlined"
            fullWidth
            onChange={setFieldFromInput}
          />
          <TextField
            {...register("email")}
            label="Email"
            name="email"
            value={resource.email || ""}
            type="text"
            variant="outlined"
            fullWidth
            onChange={setFieldFromInput}
          />
        </ResponsiveStack>
        <Roles
          roles={resource.roles}
          availableRoles={resource.availableRoles}
          setRoles={(r) => setField("roles", r)}
        />
        <AddressInputs
          address={resource.legalEntity.address}
          onFieldChange={(addressObj) =>
            setField("legalEntity", merge(resource.legalEntity, addressObj))
          }
        />
      </Stack>
    </FormLayout>
  );
}

function Roles({ roles, availableRoles, setRoles }) {
  function deleteRole(id) {
    const newRoles = roles.filter((c) => c.id !== id);
    setRoles(newRoles);
  }

  function handleAdd(newRole) {
    const newRoles = [...roles, newRole];
    setRoles(newRoles);
  }

  const exisitingRoleIds = roles.map((c) => c.id);
  availableRoles = availableRoles.filter((c) => !exisitingRoleIds.includes(c.id));

  const noRoles = isEmpty(roles) && isEmpty(availableRoles);
  return (
    <Box>
      <FormLabel>Roles</FormLabel>
      <FormHelperText>
        If you remove special roles like "admin", you will be logged out of this account.
      </FormHelperText>
      <Stack direction="row" spacing={1} sx={{ mt: theme.spacing(1) }}>
        {roles.map(({ id, name }) => (
          <Chip
            key={id}
            label={name}
            color="success"
            title="Delete Role"
            onClick={() => deleteRole(id)}
            onDelete={() => deleteRole(id)}
          />
        ))}
        {!isEmpty(availableRoles) &&
          availableRoles.map((role) => (
            <Chip
              key={role.id}
              label={role.name}
              deleteIcon={<AddCircleOutlineIcon />}
              title="Add Role"
              onClick={() => handleAdd(role)}
              onDelete={() => handleAdd(role)}
            />
          ))}
        {noRoles && (
          <Typography>
            * No roles available, ask developers for help if you see this
          </Typography>
        )}
      </Stack>
    </Box>
  );
}
