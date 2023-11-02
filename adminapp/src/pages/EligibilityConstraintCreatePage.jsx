import api from "../api";
import FormLayout from "../components/FormLayout";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { TextField } from "@mui/material";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function EligibilityConstraintCreatePage() {
  const navigate = useNavigate();
  const nameInput = React.useRef("");
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();
  const submit = () => {
    busy();
    api
      .createEligibilityConstraint({ name: nameInput.current.value })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  };
  return (
    <FormLayout
      title="Create an Eligibility Constraint"
      subtitle="Constraints describe who can access a service. For example, if you set a
        constraint to an Offering only members with the same constraint can access it."
      onSubmit={handleSubmit(submit)}
      isBusy={isBusy}
    >
      <TextField
        {...register("name")}
        inputRef={nameInput}
        label="Name"
        type="name"
        variant="outlined"
        fullWidth
        required
      />
    </FormLayout>
  );
}
