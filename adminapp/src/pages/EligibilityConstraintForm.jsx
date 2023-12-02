import FormLayout from "../components/FormLayout";
import { TextField } from "@mui/material";
import React from "react";

export default function EligibilityConstraintForm({
  isCreate,
  resource,
  setFieldFromInput,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={isCreate ? "Create an Eligibility Constraint" : "Update Constraint"}
      subtitle="Constraints describe who can access a service. For example, if you set a
        constraint to an Offering only members with the same constraint can access it."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <TextField
        {...register("name")}
        label="Name"
        name="name"
        value={resource.name}
        type="name"
        variant="outlined"
        fullWidth
        required
        onChange={setFieldFromInput}
      />
    </FormLayout>
  );
}
