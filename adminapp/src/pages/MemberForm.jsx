import api from "../api";
import AddressInputs from "../components/AddressInputs";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import { useGlobalApiState } from "../hooks/globalApiState";
import useRoleAccess from "../hooks/useRoleAccess";
import mergeAt from "../shared/mergeAt";
import withoutAt from "../shared/withoutAt";
import AddIcon from "@mui/icons-material/Add";
import AddCircleOutlineIcon from "@mui/icons-material/AddCircleOutline";
import DeleteIcon from "@mui/icons-material/Delete";
import {
  Box,
  Chip,
  CircularProgress,
  Divider,
  FormHelperText,
  FormLabel,
  Icon,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import Button from "@mui/material/Button";
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
      title="Update Member"
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
        <TextField
          {...register("phone")}
          label="Phone"
          name="phone"
          value={resource.phone || ""}
          type="tel"
          variant="outlined"
          fullWidth
          helperText="10-digit US phone number. US numbers begin with 1."
          onChange={setFieldFromInput}
        />
        <Roles roles={resource.roles} setRoles={(r) => setField("roles", r)} />
        <Divider />
        <FormLabel>Legal Entity</FormLabel>
        <AddressInputs
          address={resource.legalEntity.address}
          onFieldChange={(addressObj) =>
            setField("legalEntity", merge(resource.legalEntity, addressObj))
          }
        />
        <Divider />
        <OrganizationMemberships
          memberships={resource.organizationMemberships}
          setMemberships={(ms) => setField("organizationMemberships", ms)}
          memberId={resource.id}
        />
      </Stack>
    </FormLayout>
  );
}

function Roles({ roles, setRoles }) {
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
function OrganizationMemberships({ memberships, setMemberships, memberId }) {
  // Include member id to associate with a new membership
  const initialOrganizationMembership = {
    verifiedOrganization: {},
    member: { id: memberId },
  };
  const handleAdd = () => {
    setMemberships([...memberships, initialOrganizationMembership]);
  };
  const handleRemove = (index) => {
    setMemberships(withoutAt(memberships, index));
  };
  function handleChange(index, fields) {
    setMemberships(mergeAt(memberships, index, fields));
  }
  return (
    <>
      <FormLabel>Organization Memberships</FormLabel>
      {memberships.map((o, i) => (
        <Membership
          key={i}
          {...o}
          index={i}
          onChange={(fields) => handleChange(i, fields)}
          onRemove={() => handleRemove(i)}
        />
      ))}
      <Button onClick={handleAdd}>
        <AddIcon /> Add Organization Membership
      </Button>
    </>
  );
}

function Membership({
  index,
  verifiedOrganization,
  unverifiedOrganizationName,
  onChange,
  onRemove,
}) {
  let orgText = "The organization the member is a part of.";
  if (unverifiedOrganizationName) {
    orgText += ` The member has identified themselves with '${unverifiedOrganizationName}.'`;
  }
  return (
    <Box sx={{ p: 2, border: "1px dashed grey" }}>
      <Stack
        direction="row"
        spacing={2}
        mb={2}
        sx={{ justifyContent: "space-between", alignItems: "center" }}
      >
        <FormLabel>Membership {index + 1}</FormLabel>
        <Button onClick={(e) => onRemove(e)} variant="warning" sx={{ marginLeft: "5px" }}>
          <Icon color="warning">
            <DeleteIcon />
          </Icon>
          Remove
        </Button>
      </Stack>
      <AutocompleteSearch
        label="Organization"
        helperText={orgText}
        value={verifiedOrganization?.name}
        fullWidth
        required
        search={api.searchOrganizations}
        style={{ flex: 1 }}
        onValueSelect={(org) => onChange({ verifiedOrganization: org })}
      />
    </Box>
  );
}
