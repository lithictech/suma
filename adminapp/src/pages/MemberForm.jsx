import AddressInputs from "../components/AddressInputs";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import RoleEditor from "../components/RoleEditor";
import { Divider, FormLabel, Stack, TextField } from "@mui/material";
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
          helperText="11-digit US phone number, begins with 1."
          onChange={setFieldFromInput}
        />
        <RoleEditor roles={resource.roles} setRoles={(r) => setField("roles", r)} />
        <Divider />
        <FormLabel>Legal Entity</FormLabel>
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
